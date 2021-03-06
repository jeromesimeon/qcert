(*
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

Require Export JsAst.JsSyntax.

Section JavaScriptAst.
  (* XXX Might be better folded in JsSyntax *)
  Inductive topdecl :=
  | strictmode : topdecl                            (** strict mode declaration *)
  | comment : string -> topdecl                     (** comment *)
  | elementdecl : element -> topdecl                (** Program element *)
  | classdecl : string -> list funcdecl -> topdecl  (** Class declarations *)
  | constdecl : string -> expr -> topdecl           (** Constant declarations *)
  .

  Definition js_ast := list topdecl.

End JavaScriptAst.

