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

Section NNRCExt.

  Require Import String.
  Require Import List.
  Require Import Arith.
  Require Import EquivDec.
  Require Import Morphisms.
  Require Import Arith Max.

  Require Import Bool.

  Require Import Peano_dec.
  Require Import EquivDec Decidable.

  Require Import Utils BasicRuntime.
  Require Import NNRC.

  (** Named Nested Relational Calculus - Extended *)

  Context {fruntime:foreign_runtime}.
  Context {h:brand_relation_t}.
  
  Section macros.
    Definition nnrc_group_by (g:string) (sl:list string) (e:nnrc) : nnrc :=
      let t0 := "$group0"%string in
      let t1 := "$group1"%string in
      let t2 := "$group2"%string in
      let t3 := "$group3"%string in
      NNRCLet t0 e
             (NNRCFor t2
                     (NNRCUnop ADistinct
                              (NNRCFor t1 (NNRCVar t0) (NNRCUnop (ARecProject sl) (NNRCVar t1))))
                     (NNRCBinop AConcat
                               (NNRCUnop (ARec g)
                                        (NNRCUnop AFlatten
                                                 (NNRCFor t3 (NNRCVar t0)
                                                         (NNRCIf (NNRCBinop AEq (NNRCVar t2) (NNRCUnop (ARecProject sl) (NNRCVar t3))) (NNRCVar t3) (NNRCConst (dcoll nil))))))
                               (NNRCVar t2))).

  End macros.
  
  Section translation.
    Fixpoint nnrc_ext_to_nnrc (e:nnrc) : nnrc :=
      match e with
      | NNRCVar v => NNRCVar v
      | NNRCConst d => NNRCConst d
      | NNRCBinop b e1 e2 =>
        NNRCBinop b (nnrc_ext_to_nnrc e1) (nnrc_ext_to_nnrc e2)
      | NNRCUnop u e1 =>
        NNRCUnop u (nnrc_ext_to_nnrc e1)
      | NNRCLet v e1 e2 =>
        NNRCLet v (nnrc_ext_to_nnrc e1) (nnrc_ext_to_nnrc e2)
      | NNRCFor v e1 e2 =>
        NNRCFor v (nnrc_ext_to_nnrc e1) (nnrc_ext_to_nnrc e2)
      | NNRCIf e1 e2 e3 =>
        NNRCIf (nnrc_ext_to_nnrc e1) (nnrc_ext_to_nnrc e2) (nnrc_ext_to_nnrc e3)
      | NNRCEither e1 v2 e2 v3 e3 =>
        NNRCEither (nnrc_ext_to_nnrc e1) v2 (nnrc_ext_to_nnrc e2) v3 (nnrc_ext_to_nnrc e3)
      | NNRCGroupBy g sl e1 =>
        nnrc_group_by g sl (nnrc_ext_to_nnrc e1)
      end.

    Lemma nnrc_ext_to_nnrc_is_core (e:nnrc) :
      nnrcIsCore (nnrc_ext_to_nnrc e).
    Proof.
      induction e; intros; simpl in *; auto.
      repeat (split; auto).
    Qed.
    
    Lemma core_nnrc_to_nnrc_ext_id (e:nnrc) :
      nnrcIsCore e ->
      (nnrc_ext_to_nnrc e) = e.
    Proof.
      intros.
      induction e; simpl in *.
      - reflexivity.
      - reflexivity.
      - elim H; intros.
        rewrite IHe1; auto; rewrite IHe2; auto.
      - rewrite IHe; auto.
      - elim H; intros.
        rewrite IHe1; auto; rewrite IHe2; auto.
      - elim H; intros.
        rewrite IHe1; auto; rewrite IHe2; auto.
      - elim H; intros.
        elim H1; intros.
        rewrite IHe1; auto; rewrite IHe2; auto; rewrite IHe3; auto.
      - elim H; intros.
        elim H1; intros.
        rewrite IHe1; auto; rewrite IHe2; auto; rewrite IHe3; auto.
      - contradiction. (* GroupBy case *)
    Qed.

    Lemma core_nnrc_to_nnrc_ext_idempotent (e1 e2:nnrc) :
      e1 = nnrc_ext_to_nnrc e2 ->
      nnrc_ext_to_nnrc e1 = e1.
    Proof.
      intros.
      apply core_nnrc_to_nnrc_ext_id.
      rewrite H.
      apply nnrc_ext_to_nnrc_is_core.
    Qed.

    Corollary core_nnrc_to_nnrc_ext_idempotent_corr (e:nnrc) :
      nnrc_ext_to_nnrc (nnrc_ext_to_nnrc e) = (nnrc_ext_to_nnrc e).
    Proof.
      apply (core_nnrc_to_nnrc_ext_idempotent _ e).
      reflexivity.
    Qed.
    
  End translation.

  Section semantics.
    (** Semantics of NNRCExt *)

    Definition nnrc_ext_eval (env:bindings) (e:nnrc) : option data :=
      nnrc_core_eval h env (nnrc_ext_to_nnrc e).

    Remark nnrc_ext_to_nnrc_eq (e:nnrc):
      forall env,
        nnrc_ext_eval env e = nnrc_core_eval h env (nnrc_ext_to_nnrc e).
    Proof.
      intros; reflexivity.
    Qed.

    Remark nnrc_to_nnrc_ext_eq (e:nnrc):
      nnrcIsCore e ->
      forall env,
        nnrc_core_eval h env e = nnrc_ext_eval env e.
    Proof.
      intros.
      unfold nnrc_ext_eval.
      rewrite core_nnrc_to_nnrc_ext_id.
      reflexivity.
      assumption.
    Qed.

    (* we are only sensitive to the environment up to lookup *)
    Global Instance nnrc_ext_eval_lookup_equiv_prop :
      Proper (lookup_equiv ==> eq ==> eq) nnrc_ext_eval.
    Proof.
      generalize nnrc_core_eval_lookup_equiv_prop; intros.
      unfold Proper, respectful, lookup_equiv in *; intros; subst.
      unfold nnrc_ext_eval.
      rewrite (H h x y H0 (nnrc_ext_to_nnrc y0) (nnrc_ext_to_nnrc y0)).
      reflexivity.
      reflexivity.
    Qed.
    
  End semantics.

  Section prop.
    Require Import NNRCShadow.

    Lemma nnrc_ext_to_nnrc_free_vars_same e:
      nnrc_free_vars e = nnrc_free_vars (nnrc_ext_to_nnrc e).
    Proof.
      induction e; simpl; try reflexivity.
      - rewrite IHe1; rewrite IHe2; reflexivity.
      - assumption.
      - rewrite IHe1; rewrite IHe2; reflexivity.
      - rewrite IHe1; rewrite IHe2; reflexivity.
      - rewrite IHe1; rewrite IHe2; rewrite IHe3; reflexivity.
      - rewrite IHe1; rewrite IHe2; rewrite IHe3; reflexivity.
      - rewrite app_nil_r.
        assumption.
    Qed.

    Lemma nnrc_ext_to_nnrc_bound_vars_impl x e:
      In x (nnrc_bound_vars e) -> In x (nnrc_bound_vars (nnrc_ext_to_nnrc e)).
    Proof.
      induction e; simpl; unfold not in *; intros.
      - auto.
      - auto.
      - intuition.
        rewrite in_app_iff in H.
        rewrite in_app_iff.
        elim H; intros; auto.
      - intuition.
      - intuition.
        rewrite in_app_iff in H0.
        rewrite in_app_iff.
        elim H0; intros; auto.
      - intuition.
        rewrite in_app_iff in H0.
        rewrite in_app_iff.
        elim H0; intros; auto.
      - rewrite in_app_iff in H.
        rewrite in_app_iff in H.
        rewrite in_app_iff.
        rewrite in_app_iff.
        elim H; clear H; intros; auto.
        elim H; clear H; intros; auto.
      - rewrite in_app_iff in H.
        rewrite in_app_iff in H.
        rewrite in_app_iff.
        rewrite in_app_iff.
        elim H; clear H; intros; auto.
        elim H; clear H; intros; auto.
        elim H; clear H; intros; auto.
        elim H; clear H; intros; auto.
        right. right. auto.
        right. right. auto.
      - specialize (IHe H).
        right.
        rewrite in_app_iff.
        auto.
    Qed.

    Lemma nnrc_ext_to_nnrc_bound_vars_impl_not x e:
      ~ In x (nnrc_bound_vars (nnrc_ext_to_nnrc e)) -> ~ In x (nnrc_bound_vars e).
    Proof.
      unfold not.
      intros.
      apply H.
      apply nnrc_ext_to_nnrc_bound_vars_impl.
      assumption.
    Qed.

    Definition really_fresh_in_ext sep oldvar avoid e :=
      really_fresh_in sep oldvar avoid (nnrc_ext_to_nnrc e).
    
    Lemma really_fresh_from_free_ext sep old avoid (e:nnrc) :
      ~ In (really_fresh_in_ext sep old avoid e) (nnrc_free_vars (nnrc_ext_to_nnrc e)).
    Proof.
      unfold really_fresh_in_ext.
      intros inn1.
      apply (really_fresh_in_fresh sep old avoid (nnrc_ext_to_nnrc e)).
      repeat rewrite in_app_iff; intuition.
    Qed.

    Lemma nnrc_ext_to_nnrc_subst_comm e1 v1 e2:
      nnrc_subst (nnrc_ext_to_nnrc e1) v1 (nnrc_ext_to_nnrc e2) =
      nnrc_ext_to_nnrc (nnrc_subst e1 v1 e2).
    Proof.
      induction e1; simpl; try reflexivity.
      - destruct (equiv_dec v v1); reflexivity.
      - rewrite IHe1_1; rewrite IHe1_2; reflexivity.
      - rewrite IHe1; reflexivity.
      - rewrite IHe1_1.
        destruct (equiv_dec v v1); try reflexivity.
        rewrite IHe1_2; reflexivity.
      - rewrite IHe1_1.
        destruct (equiv_dec v v1); try reflexivity.
        rewrite IHe1_2; reflexivity.
      - rewrite IHe1_1; rewrite IHe1_2; rewrite IHe1_3; reflexivity.
      - rewrite IHe1_1.
        destruct (equiv_dec v v1);
          destruct (equiv_dec v0 v1);
          try reflexivity.
        rewrite IHe1_3; reflexivity.
        rewrite IHe1_2; reflexivity.
        rewrite IHe1_2; rewrite IHe1_3; reflexivity.
      - unfold nnrc_group_by.
        rewrite IHe1.
        unfold var in *.
        destruct (equiv_dec "$group0"%string v1); try congruence; try reflexivity.
        destruct (equiv_dec "$group1"%string v1); try congruence; try reflexivity.
        destruct (equiv_dec "$group2"%string v1); try congruence; try reflexivity.
        destruct (equiv_dec "$group3"%string v1); try congruence; try reflexivity.
        destruct (equiv_dec "$group2"%string v1); try congruence; try reflexivity.
        destruct (equiv_dec "$group3"%string v1); try congruence; try reflexivity.
    Qed.
        
    Lemma nnrc_ext_to_nnrc_rename_lazy_comm e v1 v2:
      nnrc_rename_lazy (nnrc_ext_to_nnrc e) v1 v2 =
      nnrc_ext_to_nnrc (nnrc_rename_lazy e v1 v2).
    Proof.
      induction e; unfold nnrc_rename_lazy in *; simpl; try reflexivity.
      - destruct (equiv_dec v1 v2); try reflexivity.
        destruct (equiv_dec v v1); try reflexivity.
      - destruct (equiv_dec v1 v2); reflexivity.
      - destruct (equiv_dec v1 v2); try reflexivity.
        simpl. rewrite <- IHe1; rewrite <- IHe2; reflexivity.
      - destruct (equiv_dec v1 v2); try reflexivity.
        simpl. rewrite <- IHe; reflexivity.
      - destruct (equiv_dec v1 v2); try reflexivity.
        rewrite IHe1.
        rewrite <- nnrc_ext_to_nnrc_subst_comm; simpl.
        destruct (equiv_dec v v1); try reflexivity.
        rewrite <- IHe1; reflexivity.
        rewrite <- IHe1; rewrite <- IHe2; simpl; reflexivity.
      - destruct (equiv_dec v1 v2); try reflexivity.
        rewrite IHe1.
        rewrite <- nnrc_ext_to_nnrc_subst_comm; simpl.
        destruct (equiv_dec v v1); try reflexivity.
        rewrite <- IHe1; reflexivity.
        rewrite <- IHe1; rewrite <- IHe2; simpl; reflexivity.
      - destruct (equiv_dec v1 v2); try reflexivity.
        simpl; rewrite <- IHe1; rewrite <- IHe2; rewrite <- IHe3.
        reflexivity.
      - destruct (equiv_dec v1 v2); try reflexivity.
        rewrite IHe1.
        destruct (equiv_dec v v1); try reflexivity.
        destruct (equiv_dec v0 v1); try reflexivity.
        rewrite <- nnrc_ext_to_nnrc_subst_comm; simpl.
        rewrite <- nnrc_ext_to_nnrc_subst_comm; simpl.
        rewrite <- IHe3.
        reflexivity.
        destruct (equiv_dec v0 v1); try reflexivity.
        rewrite <- nnrc_ext_to_nnrc_subst_comm; simpl.
        rewrite <- nnrc_ext_to_nnrc_subst_comm; simpl.
        rewrite <- IHe2.
        reflexivity.
        rewrite <- nnrc_ext_to_nnrc_subst_comm; simpl.
        rewrite <- nnrc_ext_to_nnrc_subst_comm; simpl.
        rewrite <- IHe2.
        rewrite <- IHe3.
        reflexivity.
      - simpl.
        unfold nnrc_group_by.
        destruct (equiv_dec v1 v2); try reflexivity.
        rewrite IHe.
        simpl; unfold nnrc_group_by.
        unfold var in *.
        destruct (equiv_dec "$group0"%string v1); try congruence; try reflexivity.
        destruct (equiv_dec "$group1"%string v1); try congruence; try reflexivity.
        destruct (equiv_dec "$group2"%string v1); try congruence; try reflexivity.
        destruct (equiv_dec "$group3"%string v1); try congruence; try reflexivity.
        destruct (equiv_dec "$group2"%string v1); try congruence; try reflexivity.
        destruct (equiv_dec "$group3"%string v1); try congruence; try reflexivity.
    Qed.

    (* unshadow properties for extended NNRC *)
    Lemma unshadow_over_nnrc_ext_idem sep renamer avoid e:
      (nnrc_ext_to_nnrc (unshadow sep renamer avoid (nnrc_ext_to_nnrc e))) =
      (unshadow sep renamer avoid (nnrc_ext_to_nnrc e)).
    Proof.
      generalize (unshadow_preserve_core sep renamer avoid (nnrc_ext_to_nnrc e)); intros.
      rewrite core_nnrc_to_nnrc_ext_id.
      reflexivity.
      apply H.
      apply nnrc_ext_to_nnrc_is_core.
    Qed.

    Lemma nnrc_ext_eval_cons_subst e env v x v' :
      ~ (In v' (nnrc_free_vars e)) ->
      ~ (In v' (nnrc_bound_vars e)) ->
      nnrc_ext_eval ((v',x)::env) (nnrc_subst e v (NNRCVar v')) = 
      nnrc_ext_eval ((v,x)::env) e.
    Proof.
      revert env v x v'.
      nnrc_cases (induction e) Case; simpl; unfold equiv_dec;
      unfold nnrc_ext_eval in *; unfold var in *; trivial; intros; simpl.
      - Case "NNRCVar"%string.
        intuition. destruct (string_eqdec v0 v); simpl; subst; intuition.
        + match_destr; intuition. simpl. dest_eqdec; intuition.
          rewrite e0.
          destruct (equiv_dec v0 v0); try congruence.
        + match_destr; subst; simpl; dest_eqdec; intuition.
          destruct (equiv_dec v v0); try congruence.
      - Case "NNRCBinop"%string.
        rewrite nin_app_or in H. f_equal; intuition.
      - f_equal; intuition.
      - rewrite nin_app_or in H. rewrite IHe1 by intuition.
        case_eq (nnrc_core_eval h ((v0, x) :: env) (nnrc_ext_to_nnrc e1)); trivial; intros d deq.
        destruct (string_eqdec v v0); unfold Equivalence.equiv in *; subst; simpl.
        + generalize (@nnrc_core_eval_remove_duplicate_env _ h nil v0 d nil); 
          simpl; intros rr1; rewrite rr1.
          destruct (string_eqdec v0 v'); unfold Equivalence.equiv in *; subst.
          * generalize (@nnrc_core_eval_remove_duplicate_env _ h nil v' d nil); 
            simpl; auto.
          * generalize (@nnrc_core_eval_remove_free_env _ h ((v0,d)::nil)); 
            simpl; intros rr2; apply rr2. intuition.
            elim H3. apply remove_in_neq; auto.
            rewrite nnrc_ext_to_nnrc_free_vars_same; auto.
        + destruct (string_eqdec v v'); unfold Equivalence.equiv in *; subst; [intuition | ].
          generalize (@nnrc_core_eval_swap_neq _ h nil v d); simpl; intros rr2; 
          repeat rewrite rr2 by trivial.
          apply IHe2.
          * intros nin; intuition. elim H2; apply remove_in_neq; auto.
          * intuition.
      - rewrite nin_app_or in H. rewrite IHe1 by intuition.
        case_eq (nnrc_core_eval h ((v0, x) :: env) (nnrc_ext_to_nnrc e1)); trivial; intros d deq.
        destruct d; trivial.
        f_equal.
        apply rmap_ext; intros.
        destruct (string_eqdec v v0); unfold Equivalence.equiv in *; subst; simpl.
        + generalize (@nnrc_core_eval_remove_duplicate_env _ h nil v0 x0 nil); 
          simpl; intros rr1; rewrite rr1.
          destruct (string_eqdec v0 v'); unfold Equivalence.equiv in *; subst.
          * generalize (@nnrc_core_eval_remove_duplicate_env _ h nil v' x0 nil); 
            simpl; auto.
          * generalize (@nnrc_core_eval_remove_free_env _ h ((v0,x0)::nil)); 
            simpl; intros rr2; apply rr2. intuition.
            elim H4. apply remove_in_neq; auto.
            rewrite nnrc_ext_to_nnrc_free_vars_same; auto.
        + destruct (string_eqdec v v'); unfold Equivalence.equiv in *; subst; [intuition | ].
          generalize (@nnrc_core_eval_swap_neq _ h nil v x0); simpl; intros rr2; 
        repeat rewrite rr2 by trivial.
        apply IHe2.
        * intros nin; intuition. elim H3; apply remove_in_neq; auto.
        * intuition.
    - rewrite nin_app_or in H; destruct H as [? HH]; 
      rewrite nin_app_or in HH, H0.
      rewrite nin_app_or in H0.
      rewrite IHe1, IHe2, IHe3; intuition.
    - apply not_or in H0; destruct H0 as [neq1 neq2].
      apply not_or in neq2; destruct neq2 as [neq2 neq3].
      repeat rewrite nin_app_or in neq3.
      repeat rewrite nin_app_or in H.
      rewrite IHe1 by intuition.
      repeat rewrite <- remove_in_neq in H by congruence.
      match_destr. destruct d; trivial.
      + match_destr; unfold Equivalence.equiv in *; subst.
        * generalize (@nnrc_core_eval_remove_duplicate_env _ h nil v1 d nil); simpl;
          intros re2; rewrite re2 by trivial.
          generalize (@nnrc_core_eval_remove_free_env _ h ((v1,d)::nil)); 
            simpl; intros re3. rewrite re3. intuition.
            rewrite <- nnrc_ext_to_nnrc_free_vars_same; intuition.
        * generalize (@nnrc_core_eval_swap_neq _ h nil v d); simpl;
          intros re1; repeat rewrite re1 by trivial.
          rewrite IHe2; intuition.
      + match_destr; unfold Equivalence.equiv in *; subst.
        * generalize (@nnrc_core_eval_remove_duplicate_env _ h nil v1 d nil); simpl;
          intros re2; rewrite re2 by trivial.
          generalize (@nnrc_core_eval_remove_free_env _ h ((v1,d)::nil)); 
          simpl; intros re3. rewrite re3. intuition.
          rewrite <- nnrc_ext_to_nnrc_free_vars_same; intuition.
        * generalize (@nnrc_core_eval_swap_neq _ h nil v0 d); simpl;
          intros re1; repeat rewrite re1 by trivial.
          rewrite IHe3; intuition.
    - rewrite IHe; try assumption.
      reflexivity.
  Qed.

  End prop.
  
End NNRCExt.

(* 
*** Local Variables: ***
*** coq-load-path: (("../../../coq" "Qcert")) ***
*** End: ***
*)