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

Section NRAEnv.
  Require Import String List Compare_dec.
  Require Import EquivDec.

  Require Import Utils BasicRuntime.
  Require Import cNRAEnv.

  (* Algebra *)

  (* By convention, "static" parameters come first, followed by
     dependent operators. This allows for instanciation on those
     parameters *)

  (* Joins *)

  Context {fruntime:foreign_runtime}.

  Definition join (op1 op2 op3 : cnraenv) : cnraenv :=
    (ANSelect op1 (ANProduct op2 op3)).

  Definition semi_join (op1 op2 op3 : cnraenv) : cnraenv :=
    ANSelect (ANUnop ANeg (ANBinop AEq (ANSelect op1 (ANProduct ((ANUnop AColl) ANID) op3)) (ANConst (dcoll nil)))) op2.

  Definition anti_join (op1 op2 op3 : cnraenv) : cnraenv :=
    ANSelect (ANBinop AEq (ANSelect op1 (ANProduct ((ANUnop AColl) ANID) op3)) (ANConst (dcoll nil))) op2.

  (* Maps *)

  Definition map_add_rec (s:string) (op1 op2 : cnraenv) : cnraenv :=
    ANMap ((ANBinop AConcat) ANID ((ANUnop (ARec s)) op1)) op2.
  Definition map_to_rec (s:string) (op : cnraenv) : cnraenv :=
    ANMap (ANUnop (ARec s) ANID) op.

  Definition flat_map (op1 op2 : cnraenv) : cnraenv :=
    ANUnop AFlatten (ANMap op1 op2).
  
  (* Projects *)
  Definition project (fields:list string) (op:cnraenv) : cnraenv
    := ANMap (ANUnop (ARecProject fields) ANID) op.

  Definition project_remove (s:string) (op:cnraenv) : cnraenv :=
    ANMap ((ANUnop (ARecRemove s)) ANID) op.

  (* Renaming *)
  (* renames field s1 to s2 *)
  Definition map_rename_rec (s1 s2:string) (op:cnraenv) : cnraenv :=
    ANMap ((ANBinop AConcat) ((ANUnop (ARec s2)) ((ANUnop (ADot s1)) ANID))
                  ((ANUnop (ARecRemove s1)) ANID)) op.

  (* Grouping *)

  (* Tricky -- you need to do two passes, and compare elements with
     the same set of attribute names which means you need to
     encapsulate each branch with distinct record names... This is not
     so great. *)

  (*
    group1 g s1 [{s1->1,r_1}, {s1->2,r_2}, {s1->1,r_3}] 
  = [{s1->1,g->[{s1->1,r_1}, {s1->1,r_3}]}, {s1->2, g->[{s1->2,r_2}]}]
  *)

  Import ListNotations.
  (* g: partition name ; sl: list of grouping attributes *)
  (* Γ[g][sl](op) ==
     χ⟨
         ID.t1.t2
         ⊗
         [ g : χ⟨ ID.t3 ⟩
               (σ⟨ π[sl](ID.t1) = π[sl](ID.t3) ⟩
                 ({ ID.t2 } × ID.t4)) ]
       ⟩
      ({ [ t4 : χ⟨[t3]⟩(op) ] } × (χ⟨[t2:ID]⟩(χ⟨[t1:ID]⟩(♯distinct(Π[sl](op)))))) *)
  
  Definition group_by_no_env (g:string) (sl:list string) (op : cnraenv) : cnraenv :=
    ANMap
      (ANBinop AConcat
               (ANUnop (ADot "1") (ANUnop (ADot "2") ANID))
               (ANUnop (ARec g)
                       (ANMap (ANUnop (ADot "3") ANID)
                              (ANSelect
                                 (ANBinop AEq
                                          (ANUnop (ARecProject sl) (ANUnop (ADot "1") ANID))
                                          (ANUnop (ARecProject sl) (ANUnop (ADot "3") ANID)))
                                 (ANProduct (ANUnop AColl (ANUnop (ADot "2") ANID))
                                            (ANUnop (ADot "4") ANID))))))
      (ANProduct
         (ANUnop AColl (ANUnop (ARec "4") (map_to_rec "3" op)))
         (map_to_rec "2" (map_to_rec "1" (ANUnop ADistinct (project sl op))))).

  (* Uses the environment to store the result of [op] -- less crazy inefficient *)
  (* g: partition name ; sl: list of grouping attributes *)
  (* Γ[g][sl](op) ==
      (χ⟨ ID ⊕ [ g : σ⟨ ENV.$key = π[sl](ID) ⟩(ENV.$pregroup) ◯ᵉ ([$key:ID] ⊕ ENV) ] ⟩
        (♯distinct(Π[sl](ENV.$pregroup)))) ◯ᵉ [ $pregroup : op ]

 *)
  Definition group_by_with_env (g:string) (sl:list string) (op : cnraenv) : cnraenv :=
    let op_pregroup := ANUnop (ADot "$pregroup") ANEnv in
    ANAppEnv
      (ANMap
         (ANBinop AConcat
                  (ANUnop (ARec g)
                          (ANAppEnv (ANSelect (ANBinop AEq
                                                       (ANUnop (ARecProject sl) ANID)
                                                       (ANUnop (ADot "$key") ANEnv))
                                              op_pregroup
                                    )
                                    (ANBinop AConcat (ANUnop (ARec "$key") ANID) ANEnv)
                          )
                  )
                  ANID
         )
         (ANUnop ADistinct (project sl op_pregroup))
      )
      (ANUnop (ARec "$pregroup") op).

  Require Import cNRAEnvEq.

  (* Unnest *)

  Definition unnest_one (s:string) (op:cnraenv) : cnraenv :=
    ANMap ((ANUnop (ARecRemove s)) ANID) (ANMapConcat ((ANUnop (ADot s)) ANID) op).

  Definition unnest_two (s1 s2:string) (op:cnraenv) : cnraenv :=
    ANMap ((ANUnop (ARecRemove s1)) ANID) (ANMapConcat (ANMap ((ANUnop (ARec s2)) ANID) ((ANUnop (ADot s1)) ANID)) op).

  (* NRAEnv for Optim *)
  (* A representation for the NRA with additional operators, usually
     helpful when considering optimization *)
  
  Inductive nraenv : Set :=
  (* Those correspond to operators in the underlying NRA *)
  | NRAEnvID : nraenv
  | NRAEnvConst : data -> nraenv
  | NRAEnvBinop : binOp -> nraenv -> nraenv -> nraenv
  | NRAEnvUnop : unaryOp -> nraenv -> nraenv
  | NRAEnvMap : nraenv -> nraenv -> nraenv
  | NRAEnvMapConcat : nraenv -> nraenv -> nraenv
  | NRAEnvProduct : nraenv -> nraenv -> nraenv
  | NRAEnvSelect : nraenv -> nraenv -> nraenv
  | NRAEnvDefault : nraenv -> nraenv -> nraenv
  | NRAEnvEither : nraenv -> nraenv -> nraenv
  | NRAEnvEitherConcat : nraenv -> nraenv -> nraenv
  | NRAEnvApp : nraenv -> nraenv -> nraenv
  | NRAEnvGetConstant : string -> nraenv
  | NRAEnvEnv : nraenv
  | NRAEnvAppEnv : nraenv -> nraenv -> nraenv
  | NRAEnvMapEnv : nraenv -> nraenv
  (* Those are additional operators *)
  | NRAEnvFlatMap : nraenv -> nraenv -> nraenv
  | NRAEnvJoin : nraenv -> nraenv -> nraenv -> nraenv
  | NRAEnvProject : list string -> nraenv -> nraenv
  | NRAEnvGroupBy : string -> list string -> nraenv -> nraenv
  .

  Global Instance nraenv_eqdec : EqDec nraenv eq.
  Proof.
    change (forall x y : nraenv,  {x = y} + {x <> y}).
    decide equality;
      try solve [apply binOp_eqdec | apply unaryOp_eqdec | apply data_eqdec | apply string_eqdec | apply list_eqdec; apply string_eqdec].
  Defined.

  Fixpoint cnraenv_of_nraenv (e:nraenv) : cnraenv :=
    match e with
      | NRAEnvID => ANID
      | NRAEnvConst d => ANConst d
      | NRAEnvBinop b e1 e2 => ANBinop b (cnraenv_of_nraenv e1) (cnraenv_of_nraenv e2)
      | NRAEnvUnop u e1 => ANUnop u (cnraenv_of_nraenv e1)
      | NRAEnvMap e1 e2 => ANMap (cnraenv_of_nraenv e1) (cnraenv_of_nraenv e2)
      | NRAEnvMapConcat e1 e2 => ANMapConcat (cnraenv_of_nraenv e1) (cnraenv_of_nraenv e2)
      | NRAEnvProduct e1 e2 => ANProduct (cnraenv_of_nraenv e1) (cnraenv_of_nraenv e2)
      | NRAEnvSelect e1 e2 => ANSelect (cnraenv_of_nraenv e1) (cnraenv_of_nraenv e2)
      | NRAEnvDefault e1 e2 => ANDefault (cnraenv_of_nraenv e1) (cnraenv_of_nraenv e2)
      | NRAEnvEither opl opr => ANEither (cnraenv_of_nraenv opl) (cnraenv_of_nraenv opr)
      | NRAEnvEitherConcat op1 op2 => ANEitherConcat (cnraenv_of_nraenv op1) (cnraenv_of_nraenv op2)
      | NRAEnvApp e1 e2 => ANApp (cnraenv_of_nraenv e1) (cnraenv_of_nraenv e2)
      | NRAEnvGetConstant s => ANGetConstant s
      | NRAEnvEnv => ANEnv
      | NRAEnvAppEnv e1 e2 => ANAppEnv (cnraenv_of_nraenv e1) (cnraenv_of_nraenv e2)
      | NRAEnvMapEnv e1 => ANMapEnv (cnraenv_of_nraenv e1)
      | NRAEnvFlatMap e1 e2 => flat_map (cnraenv_of_nraenv e1) (cnraenv_of_nraenv e2)
      | NRAEnvJoin e1 e2 e3 => join (cnraenv_of_nraenv e1) (cnraenv_of_nraenv e2) (cnraenv_of_nraenv e3)
      | NRAEnvProject ls e1 => project ls (cnraenv_of_nraenv e1)
      | NRAEnvGroupBy s ls e1 => group_by_with_env s ls (cnraenv_of_nraenv e1)
    end.

  Fixpoint nraenv_of_cnraenv (a:cnraenv) : nraenv :=
    match a with
      | ANID => NRAEnvID
      | ANConst d => NRAEnvConst d
      | ANBinop b e1 e2 => NRAEnvBinop b (nraenv_of_cnraenv e1) (nraenv_of_cnraenv e2)
      | ANUnop u e1 => NRAEnvUnop u (nraenv_of_cnraenv e1)
      | ANMap e1 e2 => NRAEnvMap (nraenv_of_cnraenv e1) (nraenv_of_cnraenv e2)
      | ANMapConcat e1 e2 => NRAEnvMapConcat (nraenv_of_cnraenv e1) (nraenv_of_cnraenv e2)
      | ANProduct e1 e2 => NRAEnvProduct (nraenv_of_cnraenv e1) (nraenv_of_cnraenv e2)
      | ANSelect e1 e2 => NRAEnvSelect (nraenv_of_cnraenv e1) (nraenv_of_cnraenv e2)
      | ANDefault e1 e2 => NRAEnvDefault (nraenv_of_cnraenv e1) (nraenv_of_cnraenv e2)
      | ANEither opl opr => NRAEnvEither (nraenv_of_cnraenv opl) (nraenv_of_cnraenv opr)
      | ANEitherConcat op1 op2 => NRAEnvEitherConcat (nraenv_of_cnraenv op1) (nraenv_of_cnraenv op2)
      | ANApp e1 e2 => NRAEnvApp (nraenv_of_cnraenv e1) (nraenv_of_cnraenv e2)
      | ANGetConstant s => NRAEnvGetConstant s
      | ANEnv => NRAEnvEnv
      | ANAppEnv e1 e2 => NRAEnvAppEnv (nraenv_of_cnraenv e1) (nraenv_of_cnraenv e2)
      | ANMapEnv e1 => NRAEnvMapEnv (nraenv_of_cnraenv e1)
    end.

  Lemma nraenv_roundtrip (a:cnraenv) :
    (cnraenv_of_nraenv (nraenv_of_cnraenv a)) = a.
  Proof.
    induction a; simpl; try reflexivity; try (rewrite IHa1; rewrite IHa2; try rewrite IHa3; reflexivity); rewrite IHa; reflexivity.
  Qed.
    
  Context (h:list(string*string)).
  
  Definition nraenv_eval c (e:nraenv) (env:data) (x:data) : option data :=
    cnraenv_eval h c (cnraenv_of_nraenv e) env x.

  Lemma initial_nraenv_ident c (e:cnraenv) (env:data) (x:data) :
    nraenv_eval c (nraenv_of_cnraenv e) env x = cnraenv_eval h c e env x.
  Proof.
    unfold nraenv_eval.
    rewrite nraenv_roundtrip.
    reflexivity.
  Qed.

End NRAEnv.

(* begin hide *)
Delimit Scope nraenv_scope with nraenv.

Notation "h ⊢ EOp @ₓ x ⊣ c ; env" := (nraenv_eval h c EOp env x) (at level 10): nraenv_scope.

(* As much as possible, notations are aligned with those of [CM93]
   S. Cluet and G. Moerkotte. Nested queries in object bases. In
   Proc. Int.  Workshop on Database Programming Languages , pages
   226-242, 1993.

   See also chapter 7.2 in:
   http://pi3.informatik.uni-mannheim.de/~moer/querycompiler.pdf
 *)

(* end hide *)

Local Open Scope string_scope.
Tactic Notation "nraenv_cases" tactic(first) ident(c) :=
  first;
  [ Case_aux c "NRAEnvID"
  | Case_aux c "NRAEnvConst"
  | Case_aux c "NRAEnvBinop"
  | Case_aux c "NRAEnvUnop"
  | Case_aux c "NRAEnvMap"
  | Case_aux c "NRAEnvMapConcat"
  | Case_aux c "NRAEnvProduct"
  | Case_aux c "NRAEnvSelect"
  | Case_aux c "NRAEnvDefault"
  | Case_aux c "NRAEnvEither"
  | Case_aux c "NRAEnvEitherConcat"
  | Case_aux c "NRAEnvApp"
  | Case_aux c "NRAEnvGetConstant"
  | Case_aux c "NRAEnvEnv"
  | Case_aux c "NRAEnvAppEnv"
  | Case_aux c "NRAEnvMapEnv"
  | Case_aux c "NRAEnvFlatMap"
  | Case_aux c "NRAEnvJoin"
  | Case_aux c "NRAEnvProject"
  | Case_aux c "NRAEnvGroupBy"].

(* 
*** Local Variables: ***
*** coq-load-path: (("../../../coq" "Qcert")) ***
*** End: ***
*)
