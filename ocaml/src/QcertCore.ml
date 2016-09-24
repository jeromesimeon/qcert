(*
 * Copyright 2015-2016 IBM Corporation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *)

open Util
open QcertConfig
open Compiler.EnhancedCompiler


type result = {
    res_emit : string * string;
    res_emit_all : (string * string) list;
    res_emit_sexp : string * string;
    res_emit_sexp_all : (string * string) list;
  }


(******************)
(* Core functions *)
(******************)

(* Message *)

let fprint_comilation_path ff gconf =
  let spath = QcertUtil.string_of_path " -> " gconf.gconf_path in
  Format.fprintf ff "Compiling from %s to %s:@\n"
    (QcertUtil.name_of_language gconf.gconf_source)
    (QcertUtil.name_of_language gconf.gconf_target);
  Format.fprintf ff "  %s@." spath

(* Parsing *)

let parse_string (gconf: QcertConfig.global_config) (query_s: string) =
  let slang = gconf.gconf_source in
  let qname, q = ParseString.parse_query_from_string slang query_s in
  (qname, q)

(* Compilation *)

let compile_query (dv_conf: CompDriver.driver_config) (schema: TypeUtil.schema) (path: CompDriver.language list) (q: CompDriver.query) : CompDriver.query list =
  let brand_model = schema.TypeUtil.sch_brand_model in
  let foreign_typing = schema.TypeUtil.sch_foreign_typing in
  let dv = CompDriver.driver_of_path brand_model dv_conf path in
  let () = QcertUtil.driver_no_error dv in
  let dv = CompDriver.fix_driver brand_model dv q in
  let queries = CompDriver.compile brand_model foreign_typing dv q in
  let () = List.iter QcertUtil.query_no_error queries in
  queries

(* Emit *)

let emit_string (dv_conf: CompDriver.driver_config) (schema: TypeUtil.schema) pretty_conf dir file_name q =
  let s = PrettyIL.pretty_query pretty_conf q in
  let brand_model = schema.TypeUtil.sch_brand_model in
  let fpref = Filename.chop_extension file_name in
  let ext = ConfigUtil.suffix_of_language (CompDriver.language_of_query brand_model q) in
  let fout = outname (target_f dir fpref) ext in
  (fout, s)

(* Emit s-expr *)

let emit_sexpr_string (schema: TypeUtil.schema) dir file_name q =
  let sexp = AstsToSExp.query_to_sexp q in
  let s = SExp.sexp_to_string sexp in
  let brand_model = schema.TypeUtil.sch_brand_model in
  let fpref = Filename.chop_extension file_name in
  let fpost = QcertUtil.name_of_language (CompDriver.language_of_query brand_model q) in
  let fout = outname (target_f dir (fpref^"_"^fpost)) ".sexp" in
  (fout, s)

(* Main *)

let main gconf (file_name, query_s) =
  let schema = gconf.gconf_schema in
  let brand_model = schema.TypeUtil.sch_brand_model in
  let (qname, q_source) = parse_string gconf query_s in
  let class_name =
    (* for Java code generation *)
    Filename.basename (Filename.chop_extension file_name)
  in
  let dv_conf = QcertConfig.driver_conf_of_global_conf gconf qname class_name in
  let queries = compile_query dv_conf schema gconf.gconf_path q_source in
  let q_target =
    begin match List.rev queries with
    | q :: _ -> q
    | _ -> raise (CACo_Error "No compilation result!")
    end
  in
  let res_emit =
    (* emit compiled query *)
    let pconf = gconf.gconf_pretty_config in
    let dir =
      begin match gconf.gconf_dir_target with
      | Some dir -> Some dir
      | None -> gconf.gconf_dir
      end
    in
    emit_string dv_conf schema pconf dir file_name q_target
  in
  let res_emit_all =
    (* Emit intermediate queries *)
    if gconf.gconf_emit_all then
      let _, l =
        List.fold_left
          (fun (fname, acc) q ->
            let pconf = gconf.gconf_pretty_config in
            let dir = gconf.gconf_dir in
            let res = emit_string dv_conf schema pconf dir fname q in
            let suff =
              ConfigUtil.suffix_of_language (CompDriver.language_of_query brand_model q)
            in
            let fname = (Filename.chop_extension fname)^suff in
            (fname, res::acc))
          (file_name, []) queries
      in
      List.rev l
    else
      []
  in
  let res_emit_sexp =
    (* emit-sexp compiled query *)
    if gconf.gconf_emit_sexp then
      emit_sexpr_string schema gconf.gconf_dir file_name q_target
    else
      ("", "")
  in
  let res_emit_sexp_all =
    (* emit-sexp-all intermediate queries *)
    if gconf.gconf_emit_sexp_all then
      let _, l =
        List.fold_left
          (fun (fname, acc) q ->
            let res = emit_sexpr_string schema gconf.gconf_dir fname q in
            let suff =
              ConfigUtil.suffix_of_language (CompDriver.language_of_query brand_model q)
            in
            let fname = (Filename.chop_extension fname)^suff in
            (fname, res::acc))
          (file_name, []) queries
      in
      List.rev l
    else
      []
  in
  { res_emit = res_emit;
    res_emit_all = res_emit_all;
    res_emit_sexp = res_emit_sexp;
    res_emit_sexp_all = res_emit_sexp_all; }
