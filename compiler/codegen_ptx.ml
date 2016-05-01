open Sast
(* open Exceptions *)
(* For sprintf *)
open Printf
(*------------------------------------------------------------ KERNEL CODE GENERATION ------------------------------------------------------------*)
(* 
let generate_kernel_fdecl kernel_f  =
  Environment.combine  [
    Generator(generate_variable_type kernel_f.kernel_r_type);
    Verbatim(" ");
    Generator(generate_id kernel_f.kernel_name);
    Verbatim("(");
    Generator(generate_parameter_list kernel_f.kernel_params);
    Verbatim("){\n");
    Generator(generate_statement_list kernel_f.kernel_body);
    Verbatim("}\n");
  ]

let rec generate_nonempty_kernel_fdecl_list kernel_fdecl_list  =
  match kernel_fdecl_list with
    | kernel_fdecl :: [] -> Environment.combine  [Generator(generate_kernel_fdecl kernel_fdecl)]
    | kernel_fdecl :: tail ->
      Environment.combine  [
        Generator(generate_kernel_fdecl kernel_fdecl);
        Verbatim("\n\n");
        Generator(generate_nonempty_kernel_fdecl_list tail)
      ]
    | [] -> raise (Empty_kernel_fdecl_list)
and generate_kernel_fdecl_list kernel_fdecl_list  =
  match kernel_fdecl_list with
    | [] -> Environment.combine  [Verbatim("")]
    | decl :: tail -> Environment.combine  [Generator(generate_nonempty_kernel_fdecl_list kernel_fdecl_list)]

 *)



(*-------------------------------------Duplicated in codegen_c-------------------------------------*)

(* Generate id *)
let generate_id id  = 
  sprintf "%s" (Utils.idtos(id))
(* Calls generate_func for every element of the list and concatenates results with specified concat symbol
   Used if you need to generate a list of something - e.x. list of statements, list of params *)
let generate_list generate_func concat mylist = 
  let list_string = String.concat concat (List.map generate_func mylist) in
  sprintf "%s" list_string

(*--------------------------------------------------------------------------*)

let generate_ptx_binary_operator operator = 
  let op = match operator with
    | Ptx_Add -> "add"
    | Ptx_Subtract -> "sub"
    | Ptx_Multiply -> "mul"
    | Ptx_Divide -> "div"
    | Ptx_Modulo -> "rem"
  in
  sprintf "%s" op

let generate_ptx_data_type data_type = 
  let t = match data_type with
    | U16 -> ".u16"
    | U32 -> ".u32"
    | U64 -> ".u64"
    | S16 -> ".s16"
    | S32 -> ".s32"
    | S64 -> ".s64"
  in
  sprintf "%s" t

let generate_ptx_register register =
  let r = match register with
    | Register(s, i) -> "%" ^ s ^ string_of_int i
  in
  sprintf "%s" r

let generate_ptx_parameter parameter =
  let p = match parameter with 
    | Parameter_register(r) -> generate_ptx_register(r)
    | Parameter_constant(c) -> string_of_int c
  in
  sprintf "%s" p

let generate_ptx_expression expression =
  let e = match expression with
  | Ptx_Binop(o, t, p1, p2, p3) -> generate_ptx_binary_operator(o) ^ generate_ptx_data_type(t) 
      ^ "     " ^ generate_ptx_parameter(p1) ^ ", " ^ generate_ptx_parameter(p2) ^ ", " 
      ^ generate_ptx_parameter(p3) ^ ";\n"
  | Ptx_Return -> "ret;\n"
  in
  sprintf "%s" e

let generate_ptx_subroutine subroutine = 
  let s =
  generate_id subroutine.routine_name ^ ": \n" ^
  generate_list generate_ptx_expression "" subroutine.routine_expressions
  in
  sprintf "%s" s


let generate_ptx_statement statement =
  let s = match statement with
  | Ptx_expression(e) -> generate_ptx_expression(e)
  in 
  sprintf "%s" s


(* Generates the ptx function string *)
(* Fill in once you have the generation for other ptx types in the sast *)
let generate_ptx_function ptx_function =
  let ptx_func = "test" in 
	sprintf "%s" ptx_func

(* Writing out to PTX file *)
let write_ptx filename ptx_string = 
  let file = open_out (filename ^ ".ptx") in 
  fprintf file "%s" ptx_string

(* Main function for generating all ptx files*)
let generate_ptx_function_files program = 
  let ptx_function_list = Utils.triple_snd(program) in
  let rec generate_ptx_files ptx_func_list =
  	match ptx_func_list with
  		| [] -> ()
  		| hd::tl ->
  			write_ptx (Utils.idtos(hd.ptx_fdecl_name)) (generate_ptx_function hd);
  			generate_ptx_files tl
  in generate_ptx_files ptx_function_list


