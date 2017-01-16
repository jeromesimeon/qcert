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

(* This includes some rewrites/simplification rules for the Nested relational calculus *)

Section TNNRCRewrite.
  Require Import String.
  Require Import List ListSet.
  Require Import Arith.
  Require Import EquivDec.
      
  Require Import Utils BasicSystem.
    
  Require Import cNNRC NNRC NNRCEq cNNRCShadow NNRCShadow.
  Require Import NNRCRewriteUtil NNRCRewrite.
  Require Import TcNNRC TNNRC TNNRCShadow TNNRCEq.

  Local Open Scope nnrc_scope.
  (* e ⇒ unshadow(e) *)

  Context {m:basic_model}.
  
  Transparent nnrc_ext_type.
  Transparent nnrc_ext_eval.
  Transparent nnrc_ext_to_nnrc.

  Lemma tunshadow_preserves_arrow sep renamer avoid (e:nnrc) :
    tnnrc_ext_rewrites_to e (unshadow sep renamer avoid e).
  Proof.
    apply nnrc_ext_rewrites_typed_with_untyped.
    rewrite unshadow_ext_preserves; reflexivity.
    intros.
    apply unshadow_ext_type.
    assumption.
  Qed.

  (* [ a : e ].a ≡ e *)

  Lemma tdot_of_rec a (e:nnrc) :
    tnnrc_ext_rewrites_to (NNRCUnop (ADot a) (NNRCUnop (ARec a) e)) e.
  Proof.
    apply nnrc_ext_rewrites_typed_with_untyped.
    - rewrite dot_of_rec; reflexivity.
    - intros.
      unfold nnrc_ext_type, nnrc_ext_to_nnrc in *.
      nnrc_inverter.
      unfold tdot, edot in *; simpl in * .
      nnrc_inverter.
      trivial.
  Qed.

  Ltac nnrc_ext_input_well_typed :=
  repeat progress
         match goal with
         | [HO:nnrc_ext_type ?Γ ?op ?τout,
               HE:bindings_type ?env ?Γ
            |- context [(nnrc_ext_eval ?env ?op)]] =>
           let xout := fresh "dout" in
           let xtype := fresh "τout" in
           let xeval := fresh "eout" in
           destruct (typed_nnrc_ext_yields_typed_data env Γ op HE HO)
             as [xout [xeval xtype]]; rewrite xeval in *; simpl
         end.

  (* (e₁ ⊕ [ a : e₂ ]).a ≡ e₂ *)

  Lemma tnnrc_dot_of_concat_rec_eq_arrow a (e1 e2:nnrc) :
    tnnrc_ext_rewrites_to (NNRCUnop (ADot a) (NNRCBinop AConcat e1 (NNRCUnop (ARec a) e2))) e2.
  Proof.
    red; intros ? ? typ1.
    split.
    - nnrc_ext_inverter.
      unfold tdot,edot,rec_concat_sort in H0.
      rewrite assoc_lookupr_drec_sort in H0.
      rewrite (assoc_lookupr_app τ₁ ((s, s0) :: nil)) in H0.
      simpl in H0.
      nnrc_inverter. trivial.
    - intros.
      unfold nnrc_ext_eval in *.
      unfold nnrc_ext_type in *.
      simpl in *.
      nnrc_inverter.
      nnrc_input_well_typed.
      dtype_inverter.
      unfold edot.
      rewrite assoc_lookupr_drec_sort.
      rewrite (assoc_lookupr_app _ ((s, _) :: nil)).
      simpl.
      nnrc_inverter.
      trivial.
  Qed.

  (* a₁ <> a₂ -> (e₁ ⊕ [ a₂ : e₂ ]).a₁ ≡ e₁.a₁ *)

  Lemma tnnrc_dot_of_concat_rec_neq_arrow a1 a2 (e1 e2:nnrc) :
    a1 <> a2 ->
    tnnrc_ext_rewrites_to (NNRCUnop (ADot a1) (NNRCBinop AConcat e1 (NNRCUnop (ARec a2) e2))) (NNRCUnop (ADot a1) e1).
  Proof.
    red; intros neq ? ? typ1.
    nnrc_ext_inverter.
    rewrite tdot_rec_concat_sort_neq in H0 by auto.
    unfold tdot, edot in H0.
    rewrite assoc_lookupr_drec_sort in H0.
    split.
    - econstructor; eauto 2.
      econstructor; eauto 2.
    - intros.
      unfold nnrc_ext_eval in *.
      unfold nnrc_ext_type in *.
      simpl in *.
      nnrc_ext_inverter.
      nnrc_input_well_typed.
      dtype_inverter.
      unfold edot.
      rewrite assoc_lookupr_drec_sort.
      rewrite (assoc_lookupr_app _ ((s, _) :: nil)).
      simpl.
      destruct (string_eqdec a1 s); [congruence | ].
      trivial.
  Qed.

  (* a₁ <> a₂ -> [ a₁ : e₁ ] ⊗ [ a₂ : e₂ ] ≡ [ a₁ : e₁ ] ⊕ [ a₂ : e₂ ] *)

  Lemma tnnrc_merge_concat_to_concat_arrow a1 a2 p1 p2:
    a1 <> a2 ->
    tnnrc_ext_rewrites_to (‵[| (a1, p1)|] ⊗ ‵[| (a2, p2)|]) (‵{|‵[| (a1, p1)|] ⊕ ‵[| (a2, p2)|]|}).
  Proof.
    intros.
    unfold nnrc_ext_eval in *.
    unfold nnrc_ext_type in *.
    apply nnrc_ext_rewrites_typed_with_untyped.
    - apply nnrc_merge_concat_to_concat; trivial.
    - intros ? ? typ.
      nnrc_ext_inverter.
      econstructor.
      + econstructor.
      + econstructor; econstructor; try econstructor; eauto 2.
        unfold merge_bindings in H2.
        match_destr_in H2.
        injection H2; trivial.
     Grab Existential Variables.
     solve[eauto].   
     solve[eauto].
  Qed.

  (* { e | x ∈ {} } ≡ {} *)

  Lemma tfor_nil_arrow x e :
    tnnrc_ext_rewrites_to (NNRCFor x ‵{||} e) ‵{||}.
  Proof.
    unfold nnrc_ext_eval in *.
    unfold nnrc_ext_type in *.
    apply nnrc_ext_rewrites_typed_with_untyped.
    - apply for_nil.
    - intros.
      nnrc_ext_inverter.
      econstructor.
      simpl.
      repeat econstructor.
  Qed.

  (* { e₁ | $t ∈ {e₁} } ≡ { LET $t := e₁ IN e₂ } *)

  Lemma tfor_singleton_to_let_arrow x e1 e2:
    tnnrc_ext_rewrites_to (NNRCFor x (NNRCUnop AColl e1) e2)
            (NNRCUnop AColl (NNRCLet x e1 e2)).
  Proof.
    unfold nnrc_ext_eval in *.
    unfold nnrc_ext_type in *.
    apply nnrc_ext_rewrites_typed_with_untyped.
    - apply for_singleton_to_let.
    - intros.
      nnrc_ext_inverter.
      econstructor.
      + econstructor.
      + econstructor; eauto.
  Qed.

  (* ♯flatten({}) ≡ {} *)

  Lemma tflatten_nil_nnrc_arrow  :
    tnnrc_ext_rewrites_to (♯flatten(‵{||})) ‵{||}.
  Proof.
    unfold nnrc_ext_eval in *.
    unfold nnrc_ext_type in *.
    apply nnrc_ext_rewrites_typed_with_untyped.
    - apply flatten_nil_nnrc.
    - intros ? ? typ.
      nnrc_ext_inverter.
      repeat (econstructor; simpl).
  Qed.

  (* ♯flatten({e}) ≡ e *)

  Lemma tflatten_singleton_nnrc_arrow e :
    tnnrc_ext_rewrites_to (♯flatten(‵{| e |})) e.
  Proof.
    red; intros; simpl.
    unfold nnrc_ext_eval in *.
    unfold nnrc_ext_type in *.
    nnrc_ext_inverter.
    split; trivial.
    intros.
    nnrc_input_well_typed.
    dtype_inverter.
    rewrite app_nil_r.
    trivial.
  Qed.

  (*  $t₁ ∉ free(e₃) ->
      { e₃ | $t₂ ∈ ♯flatten({ e₂ ? {$t₁} : {} | $t₁ ∈ e₁ }) }
        ≡ ♯flatten({ e₂ ? { LET $t₂ := $t₁ IN e₃ } : {} | $t₁ ∈ e₁ }) *)

  Lemma tmap_sigma_fusion_arrow (v1 v2:var) (e1 e2 e3:nnrc) :
    ~ In v1 (nnrc_free_vars e3) ->
    tnnrc_ext_rewrites_to
      (NNRCFor v2 
              (NNRCUnop AFlatten
                       (NNRCFor v1 e1
                               (NNRCIf e2 (NNRCUnop AColl (NNRCVar v1)) (NNRCConst (dcoll nil)))))
              e3)
      (NNRCUnop AFlatten
               (NNRCFor v1 e1
                       (NNRCIf e2
                              (NNRCUnop AColl (NNRCLet v2 (NNRCVar v1) e3))
                              (NNRCConst (dcoll nil))))).
  Proof.
    intros.
    unfold nnrc_ext_eval in *.
    unfold nnrc_ext_type in *.
    apply nnrc_ext_rewrites_typed_with_untyped.
    - rewrite (map_sigma_fusion e1 e2 e3 v1 v2 H); reflexivity.
    - intros.
      nnrc_ext_inverter.
      repeat (econstructor; eauto 2).
      + simpl. 
        match_destr.
        congruence.
      + generalize (nnrc_ext_type_remove_free_env ((v2, τ₁)::nil) v1 τ₁ τenv e3 τ₂ H); intros nt.
        simpl in nt.
        rewrite nt.
        trivial.
  Qed.

  (* { e₃ | $t₂ ∈ ♯flatten({ e₂ ? {$t₁} : {} | $t₁ ∈ e₁ }) }
       ≡ ♯flatten({ e₂ ? { LET $t₂ := $t₁ IN e₃ } : {} | $t₁ ∈ e₁ }) *)

  Lemma tmap_sigma_fusion_samevar_arrow (v1:var) (e1 e2 e3:nnrc) :
    tnnrc_ext_rewrites_to
      (NNRCFor v1 
              (NNRCUnop AFlatten
                       (NNRCFor v1 e1
                               (NNRCIf e2 (NNRCUnop AColl (NNRCVar v1)) (NNRCConst (dcoll nil)))))
              e3)
      (NNRCUnop AFlatten
               (NNRCFor v1 e1
                       (NNRCIf e2
                              (NNRCUnop AColl e3)
                              (NNRCConst (dcoll nil))))).
  Proof.
    intros.
    unfold nnrc_ext_eval in *.
    unfold nnrc_ext_type in *.
    apply nnrc_ext_rewrites_typed_with_untyped.
    - rewrite (map_sigma_fusion_samevar e1 e2 e3 v1); reflexivity.
    - intros.
      nnrc_ext_inverter.
      repeat (econstructor; eauto 2).
  Qed.

  (* bound(e2) ∩ free(e1) = ∅ ->
       LET $t := e₁ IN e₂ ≡ e₂[$t ↦ e₁] *)

  Lemma tlet_inline_disjoint_arrow x e1 e2 :
    disjoint (nnrc_bound_vars e2) (nnrc_free_vars e1) ->
    tnnrc_ext_rewrites_to
      (NNRCLet x e1 e2)
      (nnrc_subst e2 x e1).
  Proof.
    red; simpl; intros.
    nnrc_ext_inverter.
    split.
    - generalize nnrc_ext_type_cons_subst_disjoint; intro Hdisjoint.
      eapply Hdisjoint; eauto.
    - intros.
      generalize (@nnrc_ext_eval_cons_subst_disjoint _ brand_relation_brands); intro Hdisjoint.
      unfold nnrc_ext_eval in *.
      unfold nnrc_ext_type in *.
      nnrc_ext_inverter.
      simpl in *.
      nnrc_input_well_typed.
      erewrite <- Hdisjoint; eauto.
  Qed.

  (* LET $t := e₁ IN e₂ ≡ rename(e₂,free(e₁))[$t ↦ e₁] *)

  Lemma tlet_inline_arrow sep renamer x e1 e2 :
    tnnrc_ext_rewrites_to
      (NNRCLet x e1 e2)
      (nnrc_subst (unshadow sep renamer (nnrc_free_vars e1) e2) x e1).
  Proof.
    transitivity (NNRCLet x e1 (unshadow sep renamer (nnrc_free_vars e1) e2)).
    - apply nnrc_ext_let_tproper; trivial.
      + reflexivity.
      + apply tunshadow_preserves_arrow.
    - apply tlet_inline_disjoint_arrow.
      unfold disjoint.
      intros.
      apply (unshadow_avoid _ _ _ _ _ H0 H).
  Qed.

  (* { e₀ | $t ∈ IF e₁ THEN e₂ ELSE e₃ }
       ≡ IF e1 THEN { e₀ | $t ∈ e₂ } ELSE  { e₀ | $t ∈ e₃ } *)

  Lemma tfor_over_if_arrow x e1 e2  e3 ebody :
    tnnrc_ext_rewrites_to (NNRCFor x (NNRCIf e1 e2 e3) ebody)
                     (NNRCIf e1 (NNRCFor x e2 ebody)
                            (NNRCFor x e3 ebody)).
  Proof.
    apply nnrc_ext_rewrites_typed_with_untyped.
    - apply for_over_if.
    - intros ? ? typ.
      nnrc_ext_inverter.
      repeat (econstructor; eauto 2).
  Qed.

  (* {$tl,$tr} ∩ free(e₀) = ∅ ->
      { e₀ | $t ∈ (Either e₁ $tl el $tr er) } 
        ≡ Either e₁ $tl { e₀ | $t ∈ el } $tr { e₀ | $t ∈ er} *)

  Lemma tfor_over_either_disjoint_arrow x e1 xl el xr er ebody:
    disjoint (xl::xr::nil) (nnrc_free_vars ebody) ->
    tnnrc_ext_rewrites_to (NNRCFor x (NNRCEither e1 xl el xr er) ebody)
            (NNRCEither e1
                       xl (NNRCFor x el ebody)
                       xr (NNRCFor x er ebody)).
  Proof.
    intros disj.
    apply nnrc_ext_rewrites_typed_with_untyped.
    - apply for_over_either_disjoint; trivial.
    - intros ? ? typ.
      apply disjoint_cons_inv1 in disj.
      destruct disj as [disj nin1].
      apply disjoint_cons_inv1 in disj.
      destruct disj as [_ nin2].
      nnrc_ext_inverter.
      econstructor; eauto 2.
      + econstructor; eauto 2.
        generalize (@nnrc_ext_type_remove_free_env m ((x,τ₁)::nil) xl τl τenv ebody)
        ; simpl; intros re1; unfold nnrc_ext_eval in *;
        unfold nnrc_ext_type in *; simpl in *; rewrite re1; trivial.
      + econstructor; eauto 2.
        generalize (@nnrc_ext_type_remove_free_env m ((x,τ₁)::nil) xr τr τenv ebody)
        ; simpl; intros re1; unfold nnrc_ext_eval in *;
        unfold nnrc_ext_type in *; simpl in *; rewrite re1; trivial.
  Qed.

  Lemma tnnrceither_rename_l_arrow e1 xl el xr er xl' :
    ~ In xl' (nnrc_free_vars el) ->
    ~ In xl' (nnrc_bound_vars el) ->
    tnnrc_ext_rewrites_to (NNRCEither e1 xl el xr er)
            (NNRCEither e1 xl' (nnrc_subst el xl (NNRCVar xl')) xr er).
  Proof.
    intros nfree nbound.
    apply nnrc_ext_rewrites_typed_with_untyped.
    - apply nnrceither_rename_l; trivial.
    - intros.
      nnrc_ext_inverter.
      econstructor; eauto 2.
      generalize nnrc_ext_type_cons_subst; intros Hsubst;
      unfold nnrc_ext_eval in *;
      unfold nnrc_ext_type in *; simpl in *; 
      apply Hsubst; trivial.
  Qed.

  Lemma tnnrceither_rename_r_arrow e1 xl el xr er xr' :
    ~ In xr' (nnrc_free_vars er) ->
    ~ In xr' (nnrc_bound_vars er) ->
    tnnrc_ext_rewrites_to (NNRCEither e1 xl el xr er)
            (NNRCEither e1 xl el xr' (nnrc_subst er xr (NNRCVar xr'))).
  Proof.
    intros nfree nbound.
    apply nnrc_ext_rewrites_typed_with_untyped.
    - apply nnrceither_rename_r; trivial.
    - intros.
      nnrc_ext_inverter.
      econstructor; eauto 2.
      generalize nnrc_ext_type_cons_subst; intros Hsubst;
      unfold nnrc_ext_eval in *;
      unfold nnrc_ext_type in *; simpl in *; 
      apply Hsubst; trivial.
  Qed.

  Lemma tfor_over_either_arrow sep x e1 xl el xr er ebody:
    tnnrc_ext_rewrites_to (NNRCFor x (NNRCEither e1 xl el xr er) ebody)
            (    let xl' := really_fresh_in sep xl (nnrc_free_vars el ++ nnrc_bound_vars el) ebody in
                 let xr' := really_fresh_in sep xr (nnrc_free_vars er ++ nnrc_bound_vars er) ebody in
              (NNRCEither e1
                       xl' (NNRCFor x (nnrc_subst el xl (NNRCVar xl')) ebody)
                       xr' (NNRCFor x (nnrc_subst er xr (NNRCVar xr')) ebody))).
  Proof.
    simpl.
    transitivity (NNRCFor x (NNRCEither e1
                                       (really_fresh_in sep xl (nnrc_free_vars el ++ nnrc_bound_vars el) ebody)
                                       (nnrc_subst el xl (NNRCVar (really_fresh_in sep xl (nnrc_free_vars el ++ nnrc_bound_vars el) ebody)))
                                       (really_fresh_in sep xr (nnrc_free_vars er ++ nnrc_bound_vars er) ebody)
                                       (nnrc_subst er xr (NNRCVar (really_fresh_in sep xr (nnrc_free_vars er ++ nnrc_bound_vars er) ebody)))) ebody).
    - rewrite <- tnnrceither_rename_l_arrow; simpl.
      rewrite <- tnnrceither_rename_r_arrow; simpl.
      reflexivity.
      + intro inn.
        assert (inn2:In (really_fresh_in sep xr (nnrc_free_vars er ++ nnrc_bound_vars er) ebody)
                    (nnrc_free_vars er ++ nnrc_bound_vars er))
               by (rewrite in_app_iff; intuition).
        apply really_fresh_from_avoid in inn2; trivial.
      + intro inn.
        assert (inn2:In (really_fresh_in sep xr (nnrc_free_vars er ++ nnrc_bound_vars er) ebody)
                    (nnrc_free_vars er ++ nnrc_bound_vars er))
               by (rewrite in_app_iff; intuition).
        apply really_fresh_from_avoid in inn2; trivial.
      + intro inn.
        assert (inn2:In (really_fresh_in sep xl (nnrc_free_vars el ++ nnrc_bound_vars el) ebody)
                    (nnrc_free_vars el ++ nnrc_bound_vars el))
               by (rewrite in_app_iff; intuition).
        apply really_fresh_from_avoid in inn2; trivial.
      + intro inn.
        assert (inn2:In (really_fresh_in sep xl (nnrc_free_vars el ++ nnrc_bound_vars el) ebody)
                    (nnrc_free_vars el ++ nnrc_bound_vars el))
               by (rewrite in_app_iff; intuition).
        apply really_fresh_from_avoid in inn2; trivial.
    - apply tfor_over_either_disjoint_arrow.
      red; simpl; intuition; subst;
        apply really_fresh_from_free in H0; trivial.
  Qed.  

  Lemma tnnrcunop_over_either_arrow op e1 xl el xr er:
    tnnrc_ext_rewrites_to
      (NNRCUnop op (NNRCEither e1 xl el xr er))
      (NNRCEither e1 xl (NNRCUnop op el) xr (NNRCUnop op er)).
  Proof.
    apply nnrc_ext_rewrites_typed_with_untyped.
    - apply nnrcunop_over_either.
    - intros.
      nnrc_ext_inverter.
      repeat (econstructor; eauto 2).
    Qed.

  Lemma tnnrcunop_over_if_arrow op e1 e2 e3:
    tnnrc_ext_rewrites_to
      (NNRCUnop op (NNRCIf e1 e2 e3))
      (NNRCIf e1 (NNRCUnop op e2) (NNRCUnop op e3)).
  Proof.
    apply nnrc_ext_rewrites_typed_with_untyped.
    - apply nnrcunop_over_if.
    - intros.
      nnrc_ext_inverter.
      repeat (econstructor; eauto 2).
    Qed.

  (* ♯flatten({ e1 ? { $t1 } : {} | $t1 ∈ { e2 } }) ≡ LET $t1 := e2 IN e1 ? { $t1 } : {} *)

  Lemma tsigma_to_if_arrow (e1 e2:nnrc) (v:var) :
    tnnrc_ext_rewrites_to
      (NNRCUnop AFlatten
               (NNRCFor v (NNRCUnop AColl e2)
                       (NNRCIf e1
                              (NNRCUnop AColl (NNRCVar v))
                              (NNRCConst (dcoll nil)))))
      (NNRCLet v e2 (NNRCIf e1 (NNRCUnop AColl (NNRCVar v)) (NNRCConst (dcoll nil)))).
  Proof.
    apply nnrc_ext_rewrites_typed_with_untyped.
    - rewrite sigma_to_if; reflexivity.
    - intros.
      nnrc_ext_inverter.
      repeat (econstructor; eauto 2).
      simpl.
      nnrc_ext_inverter.
      trivial.
  Qed.

  Ltac casermap H := match type of H with
      | context [rmap ?x ?l] =>
        let fr := fresh "eqq" in
        case_eq (rmap x l); [intros ? fr | intros fr];
          rewrite fr in H
             end; simpl in H.

  Lemma tcount_over_flat_for_either_if_nil_arrow v e1 xl e11 e12 xr ehead :
    tnnrc_ext_rewrites_to
      (♯count(♯flatten(NNRCFor v
                              ehead (NNRCEither e1 xl
                                               (NNRCIf e11(‵{| e12|}) ‵{||}) xr ‵{||}))))
      (♯count(♯flatten(NNRCFor v
                              ehead (NNRCEither e1 xl
                                               (NNRCIf e11(‵{| ‵(dunit) |}) ‵{||}) xr ‵{||})))).
  Proof.
    red; intros.
    invcs H.
    invcs H5.
    invcs H2.
    invcs H3.
    rtype_equalizer.
    subst.
    invcs H6.
    apply Coll_right_inv in H4.
    subst.
    invcs H5.
    invcs H9.
    split.
    - econstructor; [econstructor| ].
      econstructor; [econstructor | ].
      econstructor; eauto 2.
      econstructor.
      + eauto.
      + econstructor.
        * eauto.
        * repeat (econstructor; simpl). 
        * repeat (econstructor; simpl). 
      + repeat (econstructor; simpl). 
    - intros; simpl.
      destruct (typed_nnrc_ext_yields_typed_data _ _ _ H H2) as [?[eqq1 typ1]].
      unfold nnrc_ext_eval in *;
      unfold nnrc_ext_type in *; simpl in *;
      rewrite eqq1; simpl.
      destruct x; simpl; trivial.
      clear eqq1 ehead H2.
      induction l; simpl; trivial.
      inversion typ1; clear typ1; rtype_equalizer. 
      subst.
      inversion H2; clear H2; subst.
      assert (typ1':dcoll l ▹ Coll τ₁)
        by (econstructor; trivial).
      clear H5.
      specialize (IHl typ1').
      casermap IHl; [ casermap IHl | ].
      + simpl.
        assert (bt2:bindings_type ((v, a) :: env) ((v, τ₁) :: τenv))
               by (econstructor; eauto).
        destruct (typed_nnrc_ext_yields_typed_data _ _ _ bt2 H8) as [?[eqq2 typ2]].
        unfold nnrc_ext_eval in *; unfold nnrc_ext_type in *; simpl in *.
        rewrite eqq2.
        invcs H6.
        invcs H5.
        rtype_equalizer.
        subst.
        invcs typ2; rtype_equalizer.
        * subst.
          assert (tb12:bindings_type ((xl,d)::(v,a)::env) ((xl,τl)::(v,τ₁)::τenv))
            by (econstructor; eauto).
          destruct (typed_nnrc_ext_yields_typed_data _ _ _ tb12 H4) as [?[eqq12 typ12]].
          unfold nnrc_ext_eval in *; unfold nnrc_ext_type in *; simpl in *.
          rewrite eqq12; simpl.
          dtype_inverter.
          destruct (typed_nnrc_ext_yields_typed_data _ _ _ tb12 H11) as [?[eqq3 typ3]].
          unfold nnrc_ext_eval in *; unfold nnrc_ext_type in *; simpl in *.
          rewrite eqq3.
          simpl.
          { case_eq (rflatten l0);
            [intros ? reqq0 | intros reqq0];
            rewrite reqq0 in IHl;
            (case_eq (rflatten l1);
             [intros ? reqq1 | intros reqq1];
             rewrite reqq1 in IHl); simpl in IHl; inversion IHl.
            - apply of_nat_inv in H1.
              destruct x0; simpl;
              rewrite (rflatten_cons _ _ _ reqq0);
                rewrite (rflatten_cons _ _ _ reqq1); simpl;
              congruence.
            - destruct x0; simpl;
              rewrite (rflatten_cons_none _ _ reqq0);
                rewrite (rflatten_cons_none _ _ reqq1); simpl; trivial.
          }
        * subst.
          { case_eq (rflatten l0);
            [intros ? reqq0 | intros reqq0];
            rewrite reqq0 in IHl;
            (case_eq (rflatten l1);
             [intros ? reqq1 | intros reqq1];
             rewrite reqq1 in IHl); simpl in IHl; inversion IHl;
            simpl.
            - apply of_nat_inv in H1.
              rewrite (rflatten_cons _ _ _ reqq0);
                rewrite (rflatten_cons _ _ _ reqq1); simpl;
                  congruence.
            - rewrite (rflatten_cons_none _ _ reqq0);
                rewrite (rflatten_cons_none _ _ reqq1); simpl; trivial.
          }
      + cut False; [intuition | ].
        clear eqq IHl.
        induction l; simpl in eqq0; try discriminate.
        inversion typ1'; clear typ1'; rtype_equalizer. 
        subst.
        inversion H2; clear H2; subst.
        assert (typ1':dcoll l ▹ Coll τ₁)
          by (econstructor; trivial).
        clear H9.
        apply (IHl typ1'); clear IHl.
        assert (tb:bindings_type ((v,a0)::env) ((v,τ₁)::τenv))
        by (econstructor; eauto).
        destruct (typed_nnrc_ext_yields_typed_data _ _ _ tb H8) as [?[eqq1 typ1]].
        unfold nnrc_ext_eval in *; unfold nnrc_ext_type in *; simpl in *.
        rewrite eqq1 in eqq0; simpl in eqq0.
        destruct x; inversion typ1; rtype_equalizer.
        * subst.
          assert (tb2:bindings_type ((xl,x)::(v,a0)::env) ((xl,τl)::(v,τ₁)::τenv))
                 by (econstructor; eauto).
          destruct (typed_nnrc_ext_yields_typed_data _ _ _ tb2 H4) as [?[eqq2 typ2]].
          unfold nnrc_ext_eval in *; unfold nnrc_ext_type in *; simpl in *.
          rewrite eqq2 in eqq0; simpl in eqq0.
          dtype_inverter.
          destruct x1; simpl in eqq0;
            apply none_lift in eqq0; trivial.
        * subst.
          apply none_lift in eqq0; trivial.
      + cut False; [intuition | ].
        clear IHl.
        induction l; simpl in eqq; try discriminate.
        inversion typ1'; clear typ1'; rtype_equalizer. 
        subst.
        inversion H2; clear H2; subst.
        assert (typ1':dcoll l ▹ Coll τ₁)
          by (econstructor; trivial).
        clear H9.
        apply (IHl typ1'); clear IHl.
        assert (tb:bindings_type ((v,a0)::env) ((v,τ₁)::τenv))
        by (econstructor; eauto).
        destruct (typed_nnrc_ext_yields_typed_data _ _ _ tb H8) as [?[eqq1 typ1]].
        unfold nnrc_ext_eval in *; unfold nnrc_ext_type in *; simpl in *.
        rewrite eqq1 in eqq; simpl in eqq.
        destruct x; inversion typ1; rtype_equalizer.
        * subst.
          assert (tb2:bindings_type ((xl,x)::(v,a0)::env) ((xl,τl)::(v,τ₁)::τenv))
                 by (econstructor; eauto).
          destruct (typed_nnrc_ext_yields_typed_data _ _ _ tb2 H4) as [?[eqq2 typ2]].
          unfold nnrc_ext_eval in *; unfold nnrc_ext_type in *; simpl in *.
          rewrite eqq2 in eqq; simpl in eqq.
          dtype_inverter.
          invcs H6.
          invcs H11.
          rtype_equalizer.
          subst.
          destruct (typed_nnrc_ext_yields_typed_data _ _ _ tb2 H13) as [?[eqq3 typ3]].
          unfold nnrc_ext_eval in *; unfold nnrc_ext_type in *; simpl in *.
          rewrite eqq3 in eqq.
          destruct x1; simpl in eqq;
          apply none_lift in eqq; trivial.
        * subst.
          apply none_lift in eqq; trivial.
  Qed.
    
  Lemma tcount_over_flat_for_either_either_nil_arrow v e1 xl e11 xll e12 xrr xr ehead :
      tnnrc_ext_rewrites_to
        (♯count(♯flatten(NNRCFor v
                                ehead (NNRCEither e1 xl
                                           (NNRCEither e11 xll (‵{| e12|}) xrr ‵{||}) xr ‵{||}))))
        (♯count(♯flatten(NNRCFor v
                                ehead (NNRCEither e1 xl
                                           (NNRCEither e11 xll (‵{| ‵(dunit) |}) xrr ‵{||}) xr ‵{||})))).
  Proof.
    red; intros.
    invcs H.
    invcs H5.
    invcs H2.
    invcs H3.
    rtype_equalizer.
    subst.
    invcs H6.
    apply Coll_right_inv in H4.
    subst.
    invcs H5.
    invcs H9.
    split.
    - econstructor; [econstructor| ].
      econstructor; [econstructor | ].
      econstructor; eauto 2.
      econstructor.
      + eauto.
      + econstructor.
        * eauto.
        * repeat (econstructor; simpl). 
        * repeat (econstructor; simpl). 
      + repeat (econstructor; simpl). 
    - intros; simpl.
      destruct (typed_nnrc_ext_yields_typed_data _ _ _ H H2) as [?[eqq1 typ1]].
      unfold nnrc_ext_eval in *; unfold nnrc_ext_type in *; simpl in *.
      rewrite eqq1; simpl.
      destruct x; simpl; trivial.
      clear eqq1 ehead H2.
      induction l; simpl; trivial.
      inversion typ1; clear typ1; rtype_equalizer. 
      subst.
      inversion H2; clear H2; subst.
      assert (typ1':dcoll l ▹ Coll τ₁)
        by (econstructor; trivial).
      clear H4.
      specialize (IHl typ1').
      casermap IHl; [ casermap IHl | ].
      + simpl.
        assert (bt2:bindings_type ((v, a) :: env) ((v, τ₁) :: τenv))
               by (econstructor; eauto).
        destruct (typed_nnrc_ext_yields_typed_data _ _ _ bt2 H8) as [?[eqq2 typ2]].
        unfold nnrc_ext_eval in *; unfold nnrc_ext_type in *; simpl in *.
        rewrite eqq2.
        invcs H11.
        invcs H4.
        rtype_equalizer.
        subst.
        invcs typ2; rtype_equalizer.
        * subst.
          assert (tb12:bindings_type ((xl,d)::(v,a)::env) ((xl,τl)::(v,τ₁)::τenv))
            by (econstructor; eauto).
          destruct (typed_nnrc_ext_yields_typed_data _ _ _ tb12 H7) as [?[eqq12 typ12]].
          unfold nnrc_ext_eval in *; unfold nnrc_ext_type in *; simpl in *.
          rewrite eqq12; simpl.
          { invcs typ12; rtype_equalizer.
            * subst.
              assert (tb122:bindings_type ((xll,d0)::(xl,d)::(v,a)::env) ((xll,τl0)::(xl,τl)::(v,τ₁)::τenv))
            by (econstructor; eauto).
          destruct (typed_nnrc_ext_yields_typed_data _ _ _ tb122 H6) as [?[eqq3 typ3]].
          unfold nnrc_ext_eval in *; unfold nnrc_ext_type in *; simpl in *.
          rewrite eqq3.
          simpl.
          { case_eq (rflatten l0);
            [intros ? reqq0 | intros reqq0];
            rewrite reqq0 in IHl;
            (case_eq (rflatten l1);
             [intros ? reqq1 | intros reqq1];
             rewrite reqq1 in IHl); simpl in IHl; inversion IHl.
            - apply of_nat_inv in H1.
              rewrite (rflatten_cons _ _ _ reqq0);
                rewrite (rflatten_cons _ _ _ reqq1); simpl;
              congruence.
            - rewrite (rflatten_cons_none _ _ reqq0);
                rewrite (rflatten_cons_none _ _ reqq1); simpl; trivial.
          }
        * subst.
          { case_eq (rflatten l0);
            [intros ? reqq0 | intros reqq0];
            rewrite reqq0 in IHl;
            (case_eq (rflatten l1);
             [intros ? reqq1 | intros reqq1];
             rewrite reqq1 in IHl); simpl in IHl; inversion IHl;
            simpl.
            - apply of_nat_inv in H1.
              rewrite (rflatten_cons _ _ _ reqq0);
                rewrite (rflatten_cons _ _ _ reqq1); simpl;
                  congruence.
            - rewrite (rflatten_cons_none _ _ reqq0);
                rewrite (rflatten_cons_none _ _ reqq1); simpl; trivial.
          }
          }
        * subst.
          { case_eq (rflatten l0);
            [intros ? reqq0 | intros reqq0];
            rewrite reqq0 in IHl;
            (case_eq (rflatten l1);
             [intros ? reqq1 | intros reqq1];
             rewrite reqq1 in IHl); simpl in IHl; inversion IHl; simpl.
            - apply of_nat_inv in H1.
              rewrite (rflatten_cons _ _ _ reqq0);
                rewrite (rflatten_cons _ _ _ reqq1); simpl;
              congruence.
            - rewrite (rflatten_cons_none _ _ reqq0);
                rewrite (rflatten_cons_none _ _ reqq1); simpl; trivial.
          }
      + cut False; [intuition | ].
        clear eqq IHl.
        induction l; simpl in eqq0; try discriminate.
        inversion typ1'; clear typ1'; rtype_equalizer. 
        subst.
        inversion H2; clear H2; subst.
        assert (typ1':dcoll l ▹ Coll τ₁)
          by (econstructor; trivial).
        clear H5.
        apply (IHl typ1'); clear IHl.
        assert (tb:bindings_type ((v,a0)::env) ((v,τ₁)::τenv))
        by (econstructor; eauto).
        destruct (typed_nnrc_ext_yields_typed_data _ _ _ tb H8) as [?[eqq1 typ1]].
        unfold nnrc_ext_eval in *; unfold nnrc_ext_type in *; simpl in *.
        rewrite eqq1 in eqq0; simpl in eqq0.
        destruct x; invcs typ1; rtype_equalizer.
        * subst.
          assert (tb2:bindings_type ((xl,x)::(v,a0)::env) ((xl,τl)::(v,τ₁)::τenv))
                 by (econstructor; eauto).
          destruct (typed_nnrc_ext_yields_typed_data _ _ _ tb2 H7) as [?[eqq2 typ2]].
          unfold nnrc_ext_eval in *; unfold nnrc_ext_type in *; simpl in *.
          rewrite eqq2 in eqq0; simpl in eqq0.
          { invcs typ2; rtype_equalizer.
            * subst; simpl in eqq0.
              unfold lift in eqq0.
              match_destr_in eqq0.
            * subst; simpl in eqq0.
              unfold lift in eqq0.
              match_destr_in eqq0.
          }
        * subst.
          unfold lift in eqq0.
          match_destr_in eqq0.
      + cut False; [intuition | ].
        clear IHl.
        induction l; simpl in eqq; try discriminate.
        inversion typ1'; clear typ1'; rtype_equalizer. 
        subst.
        inversion H2; clear H2; subst.
        assert (typ1':dcoll l ▹ Coll τ₁)
          by (econstructor; trivial).
        clear H5.
        apply (IHl typ1'); clear IHl.
        assert (tb:bindings_type ((v,a0)::env) ((v,τ₁)::τenv))
        by (econstructor; eauto).
        destruct (typed_nnrc_ext_yields_typed_data _ _ _ tb H8) as [?[eqq1 typ1]].
        unfold nnrc_ext_eval in *; unfold nnrc_ext_type in *; simpl in *.
        rewrite eqq1 in eqq; simpl in eqq.
        destruct x; inversion typ1; rtype_equalizer.
        * subst.
          assert (tb2:bindings_type ((xl,x)::(v,a0)::env) ((xl,τl)::(v,τ₁)::τenv))
                 by (econstructor; eauto).
          destruct (typed_nnrc_ext_yields_typed_data _ _ _ tb2 H7) as [?[eqq2 typ2]].
          unfold nnrc_ext_eval in *; unfold nnrc_ext_type in *; simpl in *.
          rewrite eqq2 in eqq; simpl in eqq.
          { invcs typ2; rtype_equalizer.
            * subst.
              invcs H11.
              invcs H9.
              rtype_equalizer.
              subst.
              assert (tb12:bindings_type ((xll,d)::(xl,x)::(v,a0)::env) ((xll,τl0)::(xl,τl)::(v,τ₁)::τenv))
                 by (econstructor; eauto).
              destruct (typed_nnrc_ext_yields_typed_data _ _ _ tb12 H14) as [?[eqq12 typ12]].
              unfold nnrc_ext_eval in *; unfold nnrc_ext_type in *; simpl in *.
              rewrite eqq12 in eqq.
              simpl in eqq.
              unfold lift in eqq.
              match_destr_in eqq.
            * subst; simpl in eqq.
              unfold lift in eqq.
              match_destr_in eqq.
          }
        * subst.
          unfold lift in eqq.
          match_destr_in eqq.
  Qed.

  (****************
   * ARecProject *
   ****************)
  
  Lemma tnnrcproject_nil p :
    π[nil](p) ⇒ᶜ  ‵[||].
  Proof.
    red; simpl; intros.
    nnrc_ext_inverter.
    split.
    - econstructor. apply dtrec_full.
      simpl. rewrite rproject_nil_r; trivial.
    - intros.
      unfold nnrc_ext_eval in *; unfold nnrc_ext_type in *.
      nnrc_ext_inverter.
      nnrc_input_well_typed.
      dtype_inverter.
      rewrite rproject_nil_r.
      trivial.
  Qed.
  
  Lemma tnnrcproject_over_concat_rec_r_in sl s p₁ p₂ :
    In s sl ->
    π[sl](p₁ ⊕ ‵[| (s, p₂) |]) ⇒ᶜ π[remove string_dec s sl](p₁) ⊕ ‵[| (s, p₂) |] .
  Proof.
    red; simpl; intros.
    nnrc_ext_inverter.
    split.
    - econstructor.
      3: econstructor; [| eauto]; eauto 2; econstructor.
      2: econstructor; [|eauto]; econstructor.
      + econstructor.
        unfold rec_concat_sort.
        rewrite rproject_rec_sort_commute, rproject_app.
        rewrite <- (rec_sort_rproject_remove_in s) by (simpl; intuition).
        simpl.
        destruct (in_dec string_dec s sl); [ | intuition ].
        trivial.
    + apply (sublist_remove equiv_dec s) in H1.
      rewrite remove_domain_filter in H1.
      unfold rec_concat_sort in H1.
      rewrite rec_sort_filter_fst_commute in H1 by (simpl; intuition).
      rewrite filter_app in H1; simpl in H1.
      unfold nequiv_decb, equiv_decb in H1.
      destruct (equiv_dec s s); [| congruence].
      simpl in H1.
      rewrite app_nil_r in H1.
      rewrite sort_sorted_is_id in H1.
      * rewrite H1.
        apply sublist_domain.
        apply filter_sublist.
      * apply sorted_over_filter; trivial.
    - intros.
      unfold nnrc_ext_eval in *; unfold nnrc_ext_type in *.
      nnrc_ext_inverter.
      nnrc_input_well_typed.
      destruct dout; simpl; trivial.
      rewrite rproject_rec_sort_commute, rproject_app.
      rewrite <- (rec_sort_rproject_remove_in s) by (simpl; intuition).
      simpl.
      destruct (in_dec string_dec s sl); simpl; intuition.
      Grab Existential Variables.
      { eapply is_list_sorted_sublist.
         - eapply pf0.
         - apply sublist_domain.
           apply sublist_rproject.
      }
      { simpl; trivial. }
  Qed.

   Lemma tnnrcproject_over_const sl l :
    π[sl](NNRCConst (drec l)) ⇒ᶜ NNRCConst (drec (rproject l sl)).
  Proof.
    apply nnrc_ext_rewrites_typed_with_untyped.
    - apply nnrcproject_over_const.
    - intros.
      nnrc_ext_inverter.
      inversion H1; subst.
      rtype_equalizer. subst.
      econstructor.
      simpl.
      apply dtrec_full.
      rewrite <- rproject_map_fst_same; simpl; trivial.
      rewrite <- rproject_rec_sort_commute.
      eapply rproject_well_typed; try eassumption.
  Qed.

  Lemma tnnrcproject_over_rec_in sl s p :
    In s sl ->
    π[sl](‵[| (s, p) |]) ⇒ᶜ ‵[| (s, p) |].
  Proof.
    intros.
    apply nnrc_ext_rewrites_typed_with_untyped.
    - apply nnrcproject_over_rec_in; trivial.
    - intros.
      nnrc_ext_inverter.
      econstructor; eauto.
      destruct (@in_dec string string_dec
              s sl); [| intuition].
      econstructor.
  Qed.

  Lemma tnnrcproject_over_rec_nin sl s p :
    ~ In s sl ->
    π[sl](‵[| (s, p) |]) ⇒ᶜ ‵[||].
  Proof.
    red; simpl; intros.
    nnrc_ext_inverter.
    split.
    - econstructor; eauto 2.
      econstructor; eauto 2.
      + reflexivity.
      + destruct (@in_dec string string_dec
                        s sl); [| intuition]; [intuition | ].
        simpl.
        econstructor; eauto.
    - intros.
      unfold nnrc_ext_eval in *; unfold nnrc_ext_type in *.
      nnrc_ext_inverter.
      nnrc_input_well_typed.
      destruct (@in_dec string string_dec
                        s sl); intuition.
  Qed.

  Lemma tnnrcproject_over_concat_rec_r_nin sl s p₁ p₂ :
    ~ In s sl ->
    π[sl](p₁ ⊕ ‵[| (s, p₂) |]) ⇒ᶜ π[sl](p₁).
  Proof.
    red; simpl; intros.
    nnrc_ext_inverter.
    split.
    - econstructor; [ | eauto].
      revert pf2.
      unfold rec_concat_sort.
      rewrite rproject_rec_sort_commute, rproject_app.
      simpl.
      destruct (in_dec string_dec s sl); [intuition | ].
      rewrite app_nil_r.
      rewrite sort_sorted_is_id.
      + intros. econstructor.
        apply (sublist_nin_remove equiv_dec _ _ _ n) in H1.
        rewrite remove_domain_filter in H1.
        unfold rec_concat_sort in H1.
        rewrite rec_sort_filter_fst_commute in H1 by (simpl; intuition).
        rewrite filter_app in H1; simpl in H1.
        unfold nequiv_decb, equiv_decb in H1.
        destruct (equiv_dec s s); [| congruence].
        simpl in H1.
        rewrite app_nil_r in H1.
        rewrite sort_sorted_is_id in H1.
        * rewrite H1.
          apply sublist_domain.
          apply filter_sublist.
        * apply sorted_over_filter; trivial.
      + apply sorted_over_filter; trivial.
    - intros.
      unfold nnrc_ext_eval in *; unfold nnrc_ext_type in *.
      nnrc_ext_inverter.
      nnrc_input_well_typed.
      destruct dout; simpl; trivial.
      rewrite rproject_rec_sort_commute, rproject_app.
      simpl.
      destruct (in_dec string_dec s sl); simpl; [intuition | ].
      rewrite app_nil_r.
      rewrite sort_sorted_is_id; trivial.
      apply sorted_over_filter; trivial.
      apply data_type_normalized in τout.
      inversion τout; trivial.
  Qed.

  Lemma tnnrcproject_over_concat_rec_l_nin sl s p₁ p₂ :
    ~ In s sl ->
    π[sl](‵[| (s, p₁) |] ⊕ p₂) ⇒ᶜ π[sl](p₂).
  Proof.
    red; intros.
    nnrc_ext_inverter.
    split.
    - econstructor; [ | eauto].
      revert pf2.
      unfold rec_concat_sort.
      rewrite rproject_rec_sort_commute, rproject_app.
      simpl.
      destruct (in_dec string_dec s sl); [intuition | ].
      simpl.
      rewrite sort_sorted_is_id.
      + intros. econstructor.
        apply (sublist_nin_remove equiv_dec _ _ _ n) in H1.
        rewrite remove_domain_filter in H1.
        unfold rec_concat_sort in H1.
        rewrite rec_sort_filter_fst_commute in H1 by (simpl; intuition).
        rewrite filter_app in H1; simpl in H1.
        unfold nequiv_decb, equiv_decb in H1.
        destruct (equiv_dec s s); [| congruence].
        simpl in H1.
        rewrite sort_sorted_is_id in H1.
        * rewrite H1.
          apply sublist_domain.
          apply filter_sublist.
        * apply sorted_over_filter; trivial.
      + apply sorted_over_filter; trivial.
    - intros.
      unfold nnrc_ext_eval in *; unfold nnrc_ext_type in *.
      nnrc_ext_inverter.
      nnrc_input_well_typed.
      destruct dout0; trivial.
      simpl.
      replace (insertion_sort_insert rec_field_lt_dec (s, dout) (rec_sort l)) with
      (rec_sort ((s,dout)::l)) by reflexivity.
      rewrite rproject_rec_sort_commute.
      simpl.
      destruct (in_dec string_dec s sl); simpl; [intuition | ].
      rewrite sort_sorted_is_id; trivial.
      apply sorted_over_filter; trivial.
      apply data_type_normalized in τout0.
      inversion τout0; trivial.
  Qed.

  Lemma tnnrcproject_over_concat_recs_in_in sl s₁ p₁ s₂ p₂ :
    In s₁ sl -> In s₂ sl ->
    π[sl](‵[| (s₁, p₁) |] ⊕ ‵[| (s₂, p₂) |]) ⇒ᶜ ‵[| (s₁, p₁) |] ⊕ ‵[| (s₂, p₂) |].
  Proof.
    intros.
    apply nnrc_ext_rewrites_typed_with_untyped.
    - rewrite nnrcproject_over_concat.
      repeat rewrite nnrcproject_over_rec_in by trivial.
      reflexivity.
    - intros.
      nnrc_ext_inverter.
      econstructor; eauto 2.
      2: repeat (econstructor; eauto 2).
      2: repeat (econstructor; eauto 2).
      econstructor; eauto.
      unfold rec_concat_sort.
      rewrite rproject_rec_sort_commute, rproject_app.
      simpl.
      destruct (in_dec string_dec s sl); [| intuition ].
      destruct (in_dec string_dec s1 sl); [| intuition ].
      reflexivity.
      Grab Existential Variables.
      solve[eauto].
      solve[eauto].
  Qed.
  
  Lemma tnnrcproject_over_nnrcproject sl1 sl2 p :
    π[sl1](π[sl2](p)) ⇒ᶜ π[set_inter string_dec sl2 sl1](p).
  Proof.
    apply nnrc_ext_rewrites_typed_with_untyped.
    - apply nnrcproject_over_nnrcproject.
    - intros.
      nnrc_ext_inverter.
      generalize pf3.
      rewrite (rproject_rproject τ sl1 sl2).
      econstructor; eauto.
      econstructor.
      apply sublist_set_inter.
      trivial.
  Qed.

  Lemma tnnrcproject_over_either sl p xl p1 xr p2 :
    π[sl](NNRCEither p xl p1 xr p2) ⇒ᶜ NNRCEither p xl (π[sl](p1)) xr (π[sl](p2)).
  Proof.
    apply nnrc_ext_rewrites_typed_with_untyped.
    - apply nnrcproject_over_either.
    - intros.
      nnrc_ext_inverter.
      repeat (econstructor; eauto 2).
  Qed.

End TNNRCRewrite.

Hint Rewrite @tsigma_to_if_arrow : nnrc_rew.
Hint Rewrite @tfor_singleton_to_let_arrow : nnrc_rew.

(* 
*** Local Variables: ***
*** coq-load-path: (("../../../coq" "Qcert")) ***
*** End: ***
*)