%{ open Ast;;

    exception LexErr of string
    exception ParseErr of string
    exception ArrayErr
    
    exception Invalid_type of string
    let string_to_variable_type = function
	| "string" -> String
	| "int" -> Integer
	| dtype -> raise (Invalid_type dtype)

    let triple_fst (a,_,_) = a
    let triple_snd (_,a,_) = a
    let triple_trd (_,_,a) = a

%}

%token LPAREN RPAREN LBRACKET RBRACKET LCURLY RCURLY INDENT DEDENT COLON TERMINATOR EOF COMMA
%token DEF DEFG RETURN
%token <int> DEDENT_EOF, DEDENT_COUNT

%token ADD SUBTRACT MULTIPLY DIVIDE MODULO

%token ASSIGNMENT 

%token <int> INTEGER_LITERAL
%token <string> DATATYPE STRING_LITERAL
%token <string> IDENTIFIER

%right ASSIGNMENT
%left ADD SUBTRACT
%left MULTIPLY DIVIDE MODULO

%start program  
%type <Ast.program> program

%%

program:
    |  /* nothing */                                { [], [], [] }
    | program vdecl TERMINATOR                      { ($2 :: triple_fst $1), triple_snd $1, triple_trd $1  }
    | program kernel_fdecl                          { triple_fst $1, ($2 :: triple_snd $1),  triple_trd $1 }
    | program fdecl                                 { triple_fst $1, triple_snd $1, ($2 :: triple_trd $1)  }

identifier:
    | IDENTIFIER                                    { Identifier($1)}

fdecl:
    | variable_type DEF identifier LPAREN parameter_list RPAREN COLON INDENT function_body DEDENT
                                                    {{ 
                                                        r_type = $1;
                                                        name = $3;
                                                        params = $5;
                                                        body = $9;
                                                    }}

kernel_fdecl:
    | variable_type DEFG identifier LPAREN parameter_list RPAREN COLON INDENT function_body DEDENT
                                                    {{
                                                        kernel_r_type = $1;
                                                        kernel_name = $3;
                                                        kernel_params = $5;
                                                        kernel_body = $9;
                                                    }}

parameter_list:
    | /* nothing */                                 { [] }
    | nonempty_parameter_list                       { $1 }

nonempty_parameter_list:
    | vdecl COMMA nonempty_parameter_list           {$1 :: $3}
    | vdecl                                         { [$1] }

vdecl:
    | variable_type identifier                      {{ 
                                                        v_type = $1;
                                                        name = $2;
                                                    }}

function_body:
    | /* nothing */                                 { [] }
    | statement function_body                       { $1::$2 }
    
statement:
    | expression TERMINATOR                         { Expression($1) }
    | vdecl TERMINATOR                              { Declaration($1) }  
    | RETURN expression TERMINATOR                  { Return($2) }
    | identifier ASSIGNMENT expression TERMINATOR   { Assignment( $1, $3 ) }
    | vdecl ASSIGNMENT expression TERMINATOR        { Initialization ($1, $3) }

expression_list:
    | /* nothing */                                 { [] }   
    | nonempty_expression_list                      { $1 }

nonempty_expression_list:
    | expression COMMA nonempty_expression_list     { $1 :: $3 }
    | expression                                    { [$1] }

expression:
    | identifier LPAREN expression_list RPAREN      { Function_Call($1,$3) }
    | STRING_LITERAL                                { String_Literal($1) }
    | INTEGER_LITERAL                               { Integer_Literal($1) }
    | identifier                                    { Identifier_Expression($1) }
    | LCURLY expression_list RCURLY                 { Array_Literal($2)}
    | expression ADD expression                     { Binop($1, Add, $3) }
    | expression SUBTRACT expression                { Binop($1, Subtract, $3) }
    | expression MULTIPLY expression                { Binop($1, Multiply, $3) }
    | expression DIVIDE expression                  { Binop($1, Divide, $3) }
    | expression MODULO expression                  { Binop($1, Modulo, $3)}

variable_type:
    | DATATYPE                                      { string_to_variable_type $1 }
    | variable_type array_dimension_list                            
        { 
            let rec create_multidimensional_array vtype dim_list= 
                match dim_list with
                    | [] -> raise ArrayErr
                    | head::[] -> Array(vtype,head)
                    | head::tail -> Array((create_multidimensional_array vtype tail),head)
            in create_multidimensional_array $1 $2
             
        }

array_dimension_list:
    | LBRACKET INTEGER_LITERAL RBRACKET                              { [$2]}
    | LBRACKET INTEGER_LITERAL RBRACKET  array_dimension_list        {  $2 :: $4 }

    
