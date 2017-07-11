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

Section CompCorrect.

  Require Import String.
  Require Import Morphisms.

  (* Core libraries *)
  Require Import BasicSystem.
  Require Import TypingRuntime.

  (* Query languages *)
  Require Import SQLRuntime.
  Require Import OQLRuntime.
  Require Import LambdaNRARuntime.
  (* Rule languages *)
  Require Import CAMPRuleRuntime.
  Require Import TechRuleRuntime.
  Require Import DesignRuleRuntime.
  (* Intermediate languages *)
  Require Import NRARuntime.
  Require Import NRAEnvRuntime.
  Require Import NNRCRuntime.
  Require Import NNRCMRRuntime.
  Require Import CldMRRuntime.
  Require Import DNNRCRuntime.
  Require Import tDNNRCRuntime.
  Require Import CAMPRuntime.
  (* Target languages *)
  Require Import JavaScriptRuntime.
  Require Import JavaRuntime.
  Require Import SparkRDDRuntime.
  Require Import SparkDFRuntime.
  Require Import CloudantRuntime.

  (* Translations *)
  Require Import OQLtoNRAEnv.
  Require Import SQLtoNRAEnv.
  Require Import LambdaNRAtoNRAEnv.
  Require Import CAMPRuletoCAMP.
  Require Import TechRuletoCAMPRule.
  Require Import DesignRuletoCAMPRule.
  Require Import CAMPtoNRA.
  Require Import CAMPtocNRAEnv.
  Require Import CAMPtoNRAEnv.
  Require Import NRAtocNNRC.
  Require Import cNRAEnvtocNNRC.
  Require Import NRAEnvtoNNRC.
  Require Import cNRAEnvtoNRA.
  Require Import cNRAEnvtoNRAEnv.
  Require Import NRAEnvtocNRAEnv.
  Require Import NRAtocNRAEnv.
  Require Import NNRCtocNNRC.
  Require Import NNRCtoDNNRC.
  Require Import NNRCtoNNRCMR.
  Require Import NNRCtoJavaScript.
  Require Import NNRCtoJava.
  Require Import cNNRCtoCAMP.
  Require Import NNRCMRtoNNRC.
  Require Import NNRCMRtoSparkRDD.
  Require Import NNRCMRtoCldMR.
  Require Import NNRCMRtoDNNRC.
  Require Import CldMRtoCloudant.
  Require Import DNNRCtotDNNRC.
  Require Import tDNNRCtoSparkDF.

  (* Optimizers *)
  Require Import NRAEnvOptim.
  Require Import NNRCOptim.
  Require Import NNRCMROptim.
  Require Import tDNNRCOptim.
  Require Import OptimizerLogger.

  (* Foreign Datatypes Support *)
  Require Import ForeignToReduceOps.
  Require Import ForeignToSpark.
  Require Import ForeignCloudant.
  Require Import ForeignToCloudant.
  Require Import ForeignToJava.
  Require Import ForeignToJavaScript.
  Require Import ForeignToScala.

  (** Compiler Driver *)
  Require Import CompLang.
  Require Import CompEnv.
  Require Import CompConfig.
  Require Import CompDriver.
  Require Import CompEval.

  (* Some useful notations *)
  Local Open Scope list_scope.

  (* Context *)
  Context {ft:foreign_type}.
  Context {fr:foreign_runtime}.
  Context {fredop:foreign_reduce_op}.
  Context {fcloudant:foreign_cloudant}.
  Context {ftocloudant:foreign_to_cloudant}.
  Context {ftoredop:foreign_to_reduce_op}.
  Context {bm:brand_model}.
  Context {ftyping: foreign_typing}.
  Context {nraenv_logger:optimizer_logger string nraenv}.
  Context {nnrc_logger:optimizer_logger string nnrc}.
  Context {dnnrc_logger:optimizer_logger string (DNNRCBase.dnnrc fr (type_annotation unit) dataframe)}.
  Context {ftojs:foreign_to_javascript}.
  Context {ftojava:foreign_to_java}.
  Context {ftos:foreign_to_scala}.
  Context {ftospark:foreign_to_spark}.

  (** Note: All stops are assumed correct (i.e., not moving does not change semantics) *)
  (** Note: True/False is indicated for each edge in the compiler pipeline *)
  (** Note: For now optimization is not recorded as correct *)
  
  Definition driver_correct_javascript (dv: javascript_driver) :=
    match dv with
    | Dv_javascript_stop => True
    end.

  Definition driver_correct_java (dv: java_driver) :=
    match dv with
    | Dv_java_stop => True
    end.

  Definition driver_correct_spark_rdd (dv: spark_rdd_driver) :=
    match dv with
    | Dv_spark_rdd_stop => True
    end.

  Definition driver_correct_spark_df (dv: spark_df_driver) :=
    match dv with
    | Dv_spark_df_stop => True
    end.

  Definition driver_correct_cloudant (dv: cloudant_driver) :=
    match dv with
    | Dv_cloudant_stop => True
    end.

  Definition driver_correct_cldmr (dv: cldmr_driver) :=
    match dv with
    | Dv_cldmr_stop => True
    | Dv_cldmr_to_cloudant rulename h dv => False /\ driver_correct_cloudant dv
    end.

  Fixpoint driver_correct_dnnrc_typed {ftyping: foreign_typing} (dv: dnnrc_typed_driver) :=
    match dv with
    | Dv_dnnrc_typed_stop => True
    | Dv_dnnrc_typed_optim dv => False /\ driver_correct_dnnrc_typed dv
    | Dv_dnnrc_typed_to_spark_df rt rulename dv => False /\ driver_correct_spark_df dv
    end.

  Definition driver_correct_dnnrc (dv: dnnrc_driver) :=
    match dv with
    | Dv_dnnrc_stop => True
    | Dv_dnnrc_to_dnnrc_typed _ dv => False /\ driver_correct_dnnrc_typed dv
    end.

  Fixpoint driver_correct_camp (dv: camp_driver) :=
    match dv with
    | Dv_camp_stop => True
    | Dv_camp_to_nraenv_core dv => True /\ driver_correct_nraenv_core dv
    | Dv_camp_to_nraenv dv => True /\ driver_correct_nraenv dv
    | Dv_camp_to_nra dv => True /\ driver_correct_nra dv
    end

  with driver_correct_nra (dv: nra_driver)  :=
    match dv with
    | Dv_nra_stop => True
    | Dv_nra_optim opc dv => False /\ driver_correct_nra dv
    | Dv_nra_to_nnrc_core dv => True /\ driver_correct_nnrc_core dv
    | Dv_nra_to_nraenv_core dv => True /\ driver_correct_nraenv_core dv
    end

  with driver_correct_nraenv_core (dv: nraenv_core_driver) :=
    match dv with
    | Dv_nraenv_core_stop => True
    | Dv_nraenv_core_optim opc dv => False /\ driver_correct_nraenv_core dv
    | Dv_nraenv_core_to_nraenv dv => True /\ driver_correct_nraenv dv
    | Dv_nraenv_core_to_nnrc_core dv => True /\ driver_correct_nnrc_core dv
    | Dv_nraenv_core_to_nra dv => True /\ driver_correct_nra dv
    end

  with driver_correct_nraenv (dv: nraenv_driver) :=
    match dv with
    | Dv_nraenv_stop => True
    | Dv_nraenv_optim opc dv => False /\ driver_correct_nraenv dv
    | Dv_nraenv_to_nnrc dv => True /\ driver_correct_nnrc dv
    | Dv_nraenv_to_nraenv_core dv => True /\ driver_correct_nraenv_core dv
    end

  with driver_correct_nnrc_core (dv: nnrc_core_driver) :=
    match dv with
    | Dv_nnrc_core_stop => True
    | Dv_nnrc_core_optim opc dv => False /\ driver_correct_nnrc_core dv
    | Dv_nnrc_core_to_nnrc dv => True /\ driver_correct_nnrc dv
    | Dv_nnrc_core_to_camp avoid dv => False /\ driver_correct_camp dv (** XXX lifting issue XXX *)
    end

  with driver_correct_nnrc (dv: nnrc_driver) :=
    match dv with
    | Dv_nnrc_stop => True
    | Dv_nnrc_optim opc dv => False /\ driver_correct_nnrc dv
    | Dv_nnrc_to_nnrc_core dv => True /\ driver_correct_nnrc_core dv
    | Dv_nnrc_to_nnrcmr vinit inputs_loc dv => False /\ driver_correct_nnrcmr dv
    | Dv_nnrc_to_dnnrc inputs_loc dv => False /\ driver_correct_dnnrc dv (* XXX distr vs local issues *)
    | Dv_nnrc_to_javascript dv => False /\ driver_correct_javascript dv
    | Dv_nnrc_to_java class_name imports dv => False /\ driver_correct_java dv
    end

  with driver_correct_nnrcmr (dv: nnrcmr_driver) :=
    match dv with
    | Dv_nnrcmr_stop => True
    | Dv_nnrcmr_optim dv => False /\ driver_correct_nnrcmr dv
    | Dv_nnrcmr_to_spark_rdd rulename dv => False /\ driver_correct_spark_rdd dv
    | Dv_nnrcmr_to_nnrc dv => False /\ driver_correct_nnrc dv
    | Dv_nnrcmr_to_cldmr h dv => False /\ driver_correct_cldmr dv
    | Dv_nnrcmr_to_dnnrc dv => False /\ driver_correct_dnnrc dv
    end.

  Definition driver_correct_camp_rule (dv: camp_rule_driver) :=
    match dv with
    | Dv_camp_rule_stop => True
    | Dv_camp_rule_to_camp dv => True /\ driver_correct_camp dv
    end.

  Definition driver_correct_tech_rule (dv: tech_rule_driver) :=
    match dv with
    | Dv_tech_rule_stop => True
    | Dv_tech_rule_to_camp_rule dv => False /\ driver_correct_camp_rule dv
    end.

  Definition driver_correct_designer_rule (dv: designer_rule_driver) :=
    match dv with
    | Dv_designer_rule_stop => True
    | Dv_designer_rule_to_camp_rule dv => False /\ driver_correct_camp_rule dv
    end.

  Definition driver_correct_oql (dv: oql_driver) :=
    match dv with
    | Dv_oql_stop => True
    | Dv_oql_to_nraenv dv => True /\ driver_correct_nraenv dv
    end.

  Definition driver_correct_sql (dv: sql_driver) :=
    match dv with
    | Dv_sql_stop => True
    | Dv_sql_to_nraenv dv => False /\ driver_correct_nraenv dv
    end.

  Definition driver_correct_lambda_nra (dv: lambda_nra_driver) :=
    match dv with
    | Dv_lambda_nra_stop => True
    | Dv_lambda_nra_to_nraenv dv => True /\ driver_correct_nraenv dv
    end.

  Definition driver_correct (dv: driver)  :=
    match dv with
    | Dv_camp_rule dv => driver_correct_camp_rule dv
    | Dv_tech_rule dv => driver_correct_tech_rule dv
    | Dv_designer_rule dv => driver_correct_designer_rule dv
    | Dv_camp dv => driver_correct_camp dv
    | Dv_oql dv => driver_correct_oql dv
    | Dv_sql dv => driver_correct_sql dv
    | Dv_lambda_nra dv => driver_correct_lambda_nra dv
    | Dv_nra dv => driver_correct_nra dv
    | Dv_nraenv_core dv => driver_correct_nraenv_core dv
    | Dv_nraenv dv => driver_correct_nraenv dv
    | Dv_nnrc_core dv => driver_correct_nnrc_core dv
    | Dv_nnrc dv => driver_correct_nnrc dv
    | Dv_nnrcmr dv => driver_correct_nnrcmr dv
    | Dv_cldmr dv => driver_correct_cldmr dv
    | Dv_dnnrc dv => driver_correct_dnnrc dv
    | Dv_dnnrc_typed dv => driver_correct_dnnrc_typed dv
    | Dv_javascript dv => driver_correct_javascript dv
    | Dv_java dv => driver_correct_java dv
    | Dv_spark_rdd dv => driver_correct_spark_rdd dv
    | Dv_spark_df dv => driver_correct_spark_df dv
    | Dv_cloudant dv => driver_correct_cloudant dv
    | Dv_error s => True (* XXX ??? XXX *)
    end.

  Require Import List.

  Section eval_preserved.

    Lemma error_msg_to_false s1 :
      (forall s : string, Q_error s1 :: nil <> Q_error s :: nil) -> False.
    Proof.
      intros.
      specialize (H s1).
      congruence.
    Qed.

    Ltac elim_qerror :=
      match goal with 
      | [H:context [forall _ : string, compile _ _ <> (Q_error _ :: nil)] |- _ ] =>
        try (unfold compile in H; simpl in H; simpl;
             assert False by apply (error_msg_to_false _ H); contradiction)
      end.

    Ltac prove_same_outputs :=
      try match goal with
      | [ |- equal_outputs (lift_output (eval_camp_rule ?h ?c (lift_input ?i)))
                           (lift_output (eval_camp_rule ?h ?c (lift_input ?i))) ] =>
        destruct  (lift_output (eval_camp_rule h c (lift_input i))); simpl; try reflexivity;
        unfold equal_outputs; simpl; match_destr; auto
      | [ |- equal_outputs (lift_output (eval_oql ?h ?c (lift_input ?i)))
                           (lift_output (eval_oql ?h ?c (lift_input ?i))) ] =>
        destruct  (lift_output (eval_oql h c (lift_input i))); simpl; try reflexivity;
        unfold equal_outputs; simpl; match_destr; auto
      | [ |- equal_outputs (Ev_out_unsupported ?s1)
                           (Ev_out_unsupported ?s2) ] =>
        unfold equal_outputs; simpl; auto
      end.

    Context {h:list(string*string)}.

    Definition query_not_error (q:query) :=
      match q with
      | Q_error _ => False
      | _ => True
      end.


    (** XXX This COULD BE the main correctness theorem. Currently being worked on XXX 
          if:
            the driver [dv] is correct (i.e., only follows verified compilation paths)
          then for all input query [q]:
            for all produced compilation steps I.e., q' in the list returned by compile dv q, we have:
            q equivalent to q' I.e., for all input data, evaluation of q and q' over that data return the same output data
     *)

    Theorem compile_correct (dv:driver) :
      driver_correct dv ->
      (forall q:query,
          Forall query_not_error (compile dv q) ->
          (forall q':query,
              In q' (compile dv q) ->
              (forall ev_in, equal_outputs (eval_query h q' ev_in) (eval_query h q ev_in)))).
    Proof.
      intros.
      Transparent compile.
      destruct q.
      - destruct dv; simpl in *.
        + simpl in H0.
      admit.
    Admitted.
    
  End eval_preserved.

End CompCorrect.


(*
*** Local Variables: ***
*** coq-load-path: (("../../../coq" "Qcert")) ***
*** End: ***
*)
