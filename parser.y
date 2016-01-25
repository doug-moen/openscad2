// This is a conflict-free Bison grammar for OpenSCAD2.
// It is a work in progress; it doesn't fully match the language spec.

%token MODULE
%token FUNCTION
%token IF
%token ELSE
%token FOR
%token LET
%token INCLUDE
%token USE
%token EACH

%token ID
%token STRING
%token PATHNAME
%token NUMBER

%token LE GE EQ NE AND OR

// Used to resolve the dangling-else ambiguity,
// which causes a shift-reduct conflict.
// * NO_ELSE is the production 'expr: IF (expr) expr;'
// * ELSE is the production 'expr: IF (expr) expr ELSE expr;'
// * NO_ELSE < ELSE: NO_ELSE has lower precedence.
// If the cursor is here: 'IF (expr) expr ^ ELSE expr'
// then we want the parser to shift (try to parse an ELSE production)
// rather than reduce to a NO_ELSE production.
// Since NO_ELSE has lower precedence, we will shift.
%nonassoc NO_ELSE
%nonassoc ELSE

// No other precedence rules are used, because we are heeding the warning
// in the Bison manual, section 5.3.6, about unwanted interaction between the
// dangling-else precedence rules and other precedence rules.
// http://www.gnu.org/software/bison/manual/html_node/Non-Operators.html

%%

// This grammar tries to unify OpenSCAD expressions and statements.
// * The ! % # * prefix shape operators are added to expressions.
// * The 'f() g()' module call syntax is added to expressions, and is
//   generalized as "right associative function call". In both expressions
//   and statements, 'f g x' is equivalent to 'f(g(x))'.
// * 'if (cond) expr1 else expr2' is a conditional expression.
// * {statement_list} is an object literal, not a compound statement,
//   in both statements and expressions, but the syntax and semantics
//   are backward compatible.
// * The FOR operator is now a list/object comprehension operator
//   in both list and object literals. 'translate(t) for(i=L) model(i)'
//   is legal (in statments only, for backward compatibility), but deprecated,
//   because 'for' is used outside of an object or list literal.
//   It can be rewritten in new syntax as:
//         translate(t) {for(i=L) model(i);}     // implicit RA function call
//         translate(t) << {for(i=L) model(i);}  // explicit RA function call
//         translate(t)({for(i=L) model(i);})    // LA function call
//   and this syntax is legal as either a statement or an expression.
//   This change in the interpretation of FOR is part of the new "lazy union"
//   semantics: the shape arguments to a module are not placed in a group
//   unless {...} is written explicitly. So intersection_for is no longer
//   required, etc.
// * The LET operator is added to statements.
//
// Due to backward compatibility, the unification isn't complete.
// Statements and expressions are still distinct, and there are subtle
// differences between the statement and expression grammars.
// * In a statement, LET IF and FOR have the same precedence as module calls.
//   The !%#* prefix shape operators can be applied to any of these.
// * By contrast, in an expression, LET IF and FOR have the lowest precedence,
//   while module calls have a high precedence, higher than unary operators,
//   but lower than function calls. The !%#* prefix operators can be applied
//   to module call expressions, but not to LET and IF expressions without
//   parenthesizing them. In expressions, the ! unary operator is overloaded
//   between logical not and shape root.
// * I originally tried to give module calls the lowest predence, so you could
//   use an infix expression as the trailing argument. When I failed to find a
//   way to describe that in Bison, I added the << operator, as a compromise.
//   But now think that the explicit << operator is a good thing.
//   So now, the general syntax for low-precedence, right associative function
//   call is f << x. The << is optional in contexts where it was not required
//   historically, for backwards compatibility.
// * As a result, infix operators are not supported in statements,
//   except for the new << operator. This is okay; it's assumed that statements
//   must evaluate to shapes, and none of the other infix operators return
//   shapes.
//
// This is a bison lalr(1) grammar with no conflicts.
// The expression grammar is written in the same style as the C expression
// grammar in the C standard. I find this grammar much easier to understand
// and modify than the OpenSCAD grammar.
//
// Although "intersection_for" and "assign" can be parsed as ordinary functions,
// I need special handling for "for" and "let" due to the different syntax they
// have in expressions and statements, so the latter are keywords.
//
// For simplicity, the expression grammar is more general than the actual
// language. FOR, IF without ELSE, and the new '..' range operator are modeled
// as expression operators. A post-processing pass is needed to report an error
// if these constructs are used outside of a list literal.

statement_list
  : /*empty*/
  | statement_list statement
  | statement_list definition
  ;

statement
  : nstatement
  | ';'
  ;

// non-empty statement
nstatement
  : selection ';'
  | selection "<<" nstatement
  | r_statement
  | '!' nstatement
  | '#' nstatement
  | '%' nstatement
  | '*' nstatement
  ;

// statements that can be used as the right argument of a RA function call
// without the use of "<<". They begin with an ID, keyword or { token.
r_statement
  : r_selection r_statement
  | object_literal
  | IF '(' expr ')' statement %prec NO_ELSE
  | IF '(' expr ')' statement ELSE statement
  | LET '(' bindings ')' statement
  | FOR '(' bindings ')' statement
  | EACH statement
  ;

definition
  : ID '=' expr ';'
  | ID '=' MODULE '(' parameters ')' statement
  | USE '<' PATHNAME '>'
  | USE expr ';'
  | INCLUDE '<' PATHNAME '>'
  | INCLUDE expr ';'
  | FUNCTION ID '(' parameters ')' '=' expr ';'
  | MODULE ID '(' parameters ')' statement
  ;

expr
  : disjunction
  | disjunction '?' expr ':' expr
  | selection "<<" expr
  | IF '(' expr ')' expr %prec NO_ELSE
  | IF '(' expr ')' expr ELSE expr
  | LET '(' bindings ')' expr
  | FOR '(' bindings ')' expr
  | EACH expr
  | FUNCTION '(' parameters ')' "->" unary
  | patom "->" unary
  ;

disjunction
  : conjunction
  | disjunction OR conjunction
  ;

conjunction
  : relation
  | conjunction AND relation
  ;

relation
  : range
  | range '>' range
  | range '<' range
  | range GE range
  | range LE range
  | range EQ range
  | range NE range
  ;

range
  : sum
  | sum ".." sum
  | ".." sum
  | sum ".."
  ;

sum
  : product
  | sum '+' product
  | sum '-' product
  ;

product
  : unary
  | product '*' unary
  | product '/' unary
  | product '%' unary
  ;

// This is the precedence that C uses for unary operators.
// Most of the right associative syntax has been placed here.
unary
  : chain
  | '+' unary
  | '-' unary
  | '!' unary	// polymorphic: logical not and root shape
  | '%' unary   // highlight
  | '#' unary
  | '*' unary   // disable. only in a generator context.
  ;

// A 'chain' is a RA function call in those special cases where the "<<"
// operator can be omitted, for backward compatibility.
chain
  : selection
  | object_literal selector
  | selection r_chain
  ;

r_chain
  : r_selection
  | object_literal selector
  | r_selection r_chain
  ;

selection
  : r_selection
  | atom selector
  ;

// restricted form of selection: its first token can't begin a selector
r_selection
  : ID selector
  | NUMBER
  | STRING selector
  ;

selector
  : /*empty*/
  | selector '.' ID
  | selector '(' arguments ')'
  | selector '[' expr ']'
  ;

// An object_literal is not an atom
// because 'atom' and 'selection' are shared with 'statement'.
// So object literals have been moved above 'selection', into 'chain'.
atom
  : patom
  | '[' arguments ']'
  | '[' expr ':' expr ']'
  | '[' expr ':' expr ':' expr ']'
  ;

// This is either a parenthesized subexpression,
// or a function's formal parameter list, depending on context.
patom
  : '(' arguments ')'
  ;

object_literal
  : '{' statement_list '}'
  ;

parameters: /*empty*/ | parameter_list opt_comma ;
parameter_list: parameter | parameter_list ',' parameter ;
parameter: ID | binding ;

arguments: /*empty*/ | argument_list opt_comma ;
argument_list: argument | argument_list ',' argument ;
argument: expr | binding ;

bindings: binding_list opt_comma ;
binding_list: binding | binding_list ',' binding ;
binding: ID '=' expr ;

opt_comma: ',' | /*empty*/ ;
