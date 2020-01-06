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

Require Import List.
Require Import ZArith.
Require Import EquivDec.
Require Import RelationClasses.
Require Import Equivalence.
Require Import ToString.
Require Import String.
Require Import Utils.
Require Import DataSystem.
Require Import ForeignData.
Require Import SqlDateComponent.

Import ListNotations.
Local Open Scope list_scope.

Inductive enhanced_data : Set :=
| enhancedsqldate : SQL_DATE -> enhanced_data
| enhancedsqldateinterval : SQL_DATE_INTERVAL -> enhanced_data
.

Existing Instance sql_date_foreign_data.
Existing Instance sql_date_interval_foreign_data.

Program Instance enhanced_foreign_data : foreign_data
  := mk_foreign_data enhanced_data _ _ _ _ _ _.
Next Obligation.
  red.
  unfold equiv, complement.
  destruct x; destruct y; simpl; try solve [right; inversion 1].
  - destruct (@equiv_dec _ _ _ (@foreign_data_dec sql_date_foreign_data) s s0).
    + left; congruence.
    + right; congruence.
  - destruct (@equiv_dec _ _ _ (@foreign_data_dec sql_date_interval_foreign_data) s s0).
    + left; congruence.
    + right; congruence.
Defined.
Next Obligation.
  (* normalized? *)
  destruct a.
  - exact (@foreign_data_normalized sql_date_foreign_data s).
  - exact (@foreign_data_normalized sql_date_interval_foreign_data s).
Defined.
Next Obligation.
  destruct a.
  - exact (@foreign_data_normalize_normalizes sql_date_foreign_data s).
  - exact (@foreign_data_normalize_normalizes sql_date_interval_foreign_data s).
Defined.
Next Obligation.
  constructor.
  destruct 1.
  - exact (@toString _ (@foreign_data_tostring sql_date_foreign_data) s).
  - exact (@toString _ (@foreign_data_tostring sql_date_interval_foreign_data) s).
Defined.

Definition denhancedsqldate td := dforeign (enhancedsqldate td).
Definition denhancedsqldateinterval td := dforeign (enhancedsqldateinterval td).

Inductive enhanced_unary_op :=
| enhanced_unary_sql_date_op : sql_date_unary_op -> enhanced_unary_op.

Definition ondsqldate {A} (f : SQL_DATE -> A) (d : data) : option A :=
  match d with
  | dforeign (enhancedsqldate fd) => Some (f fd)
  | _ => None
  end.

Definition ondstring {A} (f : String.string -> A) (d : data) : option A :=
  match d with
  | dstring s => Some (f s)
  | _ => None
  end.

Definition sql_date_unary_op_interp (op:sql_date_unary_op) (d:data) : option data :=
  match op with
  | uop_sql_date_get_component part =>
    lift dnat (ondsqldate (SQL_DATE_get_component part) d)
  | uop_sql_date_from_string =>
    lift denhancedsqldate (ondstring SQL_DATE_from_string d)
  | uop_sql_date_interval_from_string =>
    lift denhancedsqldateinterval (ondstring SQL_DATE_INTERVAL_from_string d)
  end.

Definition enhanced_unary_op_interp
           (br:brand_relation_t)
           (op:enhanced_unary_op)
           (d:data) : option data :=
  match op with
  | enhanced_unary_sql_date_op f => sql_date_unary_op_interp f d
  end.

Inductive enhanced_binary_op :=
| enhanced_binary_sql_date_op : sql_date_binary_op -> enhanced_binary_op
.

Definition ondsqldate2 {A} (f : SQL_DATE -> SQL_DATE -> A) (d1 d2 : data) : option A
  := match d1, d2 with
     | dforeign (enhancedsqldate fd1), dforeign (enhancedsqldate fd2) => Some (f fd1 fd2)
     | _, _ => None
     end.

Definition ondsqldatez2 {A} (f : SQL_DATE -> Z -> A) (d1 d2 : data) : option A
  := match d1, d2 with
     | dforeign (enhancedsqldate fd1), dnat z => Some (f fd1 z)
     | _, _ => None
     end.

Definition rondboolsqldate2 (f: SQL_DATE -> SQL_DATE -> bool) (d1 d2:data) : option data
  := lift dbool (ondsqldate2 f d1 d2).

Definition sql_date_binary_op_interp
           (op:sql_date_binary_op) (d1 d2:data) : option data
  := match op with
     | bop_sql_date_plus
       => match d1, d2 with
          | dforeign (enhancedsqldate tp), dforeign (enhancedsqldateinterval td)
            => Some (denhancedsqldate (SQL_DATE_plus tp td))
          | _,_ => None
          end
     | bop_sql_date_minus
       => match d1, d2 with
          | dforeign (enhancedsqldate tp), dforeign (enhancedsqldateinterval td)
            => Some (denhancedsqldate (SQL_DATE_minus tp td))
          | _,_ => None
          end
     | bop_sql_date_ne => rondboolsqldate2 SQL_DATE_ne d1 d2
     | bop_sql_date_lt => rondboolsqldate2 SQL_DATE_lt d1 d2
     | bop_sql_date_le => rondboolsqldate2 SQL_DATE_le d1 d2
     | bop_sql_date_gt => rondboolsqldate2 SQL_DATE_gt d1 d2
     | bop_sql_date_ge => rondboolsqldate2 SQL_DATE_ge d1 d2
     | bop_sql_date_interval_between =>
       lift denhancedsqldateinterval (ondsqldate2 SQL_DATE_INTERVAL_between d1 d2)
     | bop_sql_date_set_component part =>
       lift denhancedsqldate (ondsqldatez2 (SQL_DATE_set_component part) d1 d2)
     end.

Definition enhanced_binary_op_interp
           (br:brand_relation_t)
           (op:enhanced_binary_op)
           (d1 d2:data) : option data
  := match op with
     | enhanced_binary_sql_date_op f => sql_date_binary_op_interp f d1 d2
     end.

Program Instance enhanced_foreign_operators : foreign_operators
  := { foreign_operators_unary := enhanced_unary_op
       ; foreign_operators_unary_interp := enhanced_unary_op_interp
       ; foreign_operators_unary_data_tostring := defaultDataToString
       ; foreign_operators_unary_data_totext := defaultDataToString
       ; foreign_operators_binary := enhanced_binary_op
       ; foreign_operators_binary_interp := enhanced_binary_op_interp }.
Next Obligation.
  red; unfold equiv; intros.
  change ({x = y} + {x <> y}).
  decide equality.
  - decide equality.
    decide equality.
Defined.
Next Obligation.
  constructor; intros op.
  destruct op.
  - exact (sql_date_unary_op_tostring s).
Defined.
Next Obligation.
  destruct op; simpl in H.
  - destruct s; simpl in H;
      unfold ondsqldate, denhancedsqldate, denhancedsqldateinterval, lift in H; simpl in H;
        destruct d; simpl in H; try discriminate.
    + destruct f; invcs H; repeat constructor.
    + invcs H; repeat constructor.
    + invcs H; repeat constructor.
Defined.
Next Obligation.
  red; unfold equiv; intros.
  change ({x = y} + {x <> y}).
  decide equality.
  - decide equality.
    decide equality.
Defined.
Next Obligation.
  constructor; intros op.
  destruct op.
  - exact (sql_date_binary_op_tostring s).
Defined.
Next Obligation.
  destruct op; simpl in H.
  - destruct s; simpl in H;
      unfold rondboolsqldate2, ondsqldate2, denhancedsqldate, lift in H
      ; destruct d1; simpl in H; try discriminate
      ; destruct f; simpl in H; try discriminate
      ; destruct d2; simpl in H; try discriminate
      ; try (destruct f; simpl in H; try discriminate)
      ; invcs H
      ; repeat constructor.
Qed.

Instance enhanced_foreign_runtime :
  foreign_runtime
  := mk_foreign_runtime
       enhanced_foreign_data
       enhanced_foreign_operators.

