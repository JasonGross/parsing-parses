(** * Definition of a boolean-returning CFG parser-recognizer *)
Require Import Coq.Lists.List Coq.Program.Program Coq.Program.Wf Coq.Arith.Wf_nat Coq.Arith.Compare_dec Coq.Classes.RelationClasses Coq.Strings.String.
Require Import Parsers.ContextFreeGrammar Parsers.Specification Parsers.BooleanRecognizer Parsers.MinimalParse.
Require Import Common Common.ilist Common.Wf.
Require Import Eqdep_dec.

Local Hint Extern 0 =>
match goal with
  | [ H : false = true |- _ ] => solve [ destruct (Bool.diff_false_true H) ]
  | [ H : true = false |- _ ] => solve [ destruct (Bool.diff_true_false H) ]
end.

Coercion is_true (b : bool) := b = true.

Local Open Scope string_like_scope.

Section sound.
  Section general.
    Context CharType (String : string_like CharType) (G : grammar CharType).
    Context (names_listT : Type)
            (initial_names_data : names_listT)
            (is_valid_name : names_listT -> string -> bool)
            (remove_name : names_listT -> string -> names_listT)
            (names_listT_R : names_listT -> names_listT -> Prop)
            (remove_name_dec : forall ls name, is_valid_name ls name = true
                                               -> names_listT_R (remove_name ls name) ls)
            (ntl_wf : well_founded names_listT_R)
            (remove_name_1
             : forall ls ps ps',
                 is_valid_name (remove_name ls ps) ps' = true
                 -> is_valid_name ls ps' = true)
            (remove_name_2
             : forall ls ps ps',
                 is_valid_name (remove_name ls ps) ps' = false
                 <-> is_valid_name ls ps' = false \/ ps = ps')
            (split_string_for_production
             : forall (str0 : String) (prod : production CharType), list (String * String))
            (split_string_for_production_correct
             : forall str0 prod,
                 List.Forall (fun s1s2 => fst s1s2 ++ snd s1s2 =s str0)
                             (split_string_for_production str0 prod)).

    Let P : string -> Prop
      := fun p => is_valid_name initial_names_data p = true.

    Section parts.
      Local Hint Constructors parse_of_item parse_of parse_of_production.
      Local Hint Constructors minimal_parse_of_item minimal_parse_of minimal_parse_of_production.

      Let H_subT valid
        := sub_name_listT is_valid_name valid initial_names_data.

      Section item.
        Context (str : String)
                (str_matches_name : string -> bool).

        Definition str_matches_name_soundT
          := forall name, str_matches_name name = true
                                -> parse_of_item _ G str (NonTerminal _ name).

        Definition str_matches_name_completeT Pv valid
          := forall name (Hv : Pv valid name),
               minimal_parse_of_item _ G initial_names_data is_valid_name remove_name valid str (NonTerminal _ name)
               -> str_matches_name name = true.

        Lemma parse_item_sound
              (str_matches_name_sound : str_matches_name_soundT)
              (it : item CharType)
        : parse_item String str str_matches_name it = true -> parse_of_item _ G str it.
        Proof.
          unfold parse_item, str_matches_name_soundT in *.
          repeat match goal with
                   | _ => intro
                   | [ H : context[match ?E with _ => _ end] |- _ ] => atomic E; destruct E
                   | [ |- context[match ?E with _ => _ end] ] => atomic E; destruct E
                   | [ H : _ = true |- _ ] => apply bool_eq_correct in H
                   | _ => progress subst
                   | _ => solve [ eauto ]
                 end.
        Defined.

        Lemma parse_item_complete
              valid Pv
              (H_is_valid : forall name, is_valid_name valid name = true -> Pv valid name)
              (str_matches_name_complete : str_matches_name_completeT Pv valid)
              (it : item CharType)
        : minimal_parse_of_item _ G initial_names_data is_valid_name remove_name valid str it
          -> parse_item String str str_matches_name it = true.
        Proof.
          unfold parse_item, str_matches_name_completeT in *.
          repeat match goal with
                   | _ => intro
                   | _ => reflexivity
                   | _ => assumption
                   | _ => progress subst
                   | _ => progress destruct_head ex
                   | _ => progress destruct_head and
                   | [ |- context[match ?E with _ => _ end] ] => destruct E
                   | [ |- _ = true ] => apply bool_eq_correct
                   | [ |- str_matches_name _ = true ]
                     => eapply str_matches_name_complete; [..| eassumption ]
                   | [ H : minimal_parse_of_item _ _ _ _ _ _ _ _ |- _ ] => inversion H; clear H
                   | _ => solve [ eauto ]
                 end.
        Qed.
      End item.

      Section item_ext.
        Lemma parse_item_ext
              (str : String)
              (str_matches_name1 str_matches_name2 : string -> bool)
              (it : item CharType)
              (ext : forall x, str_matches_name1 x = str_matches_name2 x)
        : parse_item String str str_matches_name1 it
          = parse_item String str str_matches_name2 it.
        Proof.
          unfold parse_item.
          destruct it; auto;
          match goal with
            | [ |- context[match ?E with _ => _ end] ] => destruct E
          end;
          auto.
        Qed.
      End item_ext.

      Section production.
        Context (p0 : String * names_listT)
                (parse_name : forall p : String * names_listT,
                                prod_relation (ltof String Length) names_listT_R p p0 ->
                                string -> bool).


        Definition parse_name_soundT
          := forall p pf name,
               @parse_name p pf name = true
               -> parse_of_item _ G (fst p) (NonTerminal _ name).

        Definition parse_name_completeT Pv p
          := forall pf name (Hv : Pv (snd p) name),
               minimal_parse_of_item _ G initial_names_data is_valid_name remove_name (snd p) (fst p) (NonTerminal _ name)
               -> @parse_name p pf name = true.

        Definition split_correctT
                   (str1 : String)
                   (split : String * String)
          := fst split ++ snd split =s str1.

        Definition split_list_correctT str1 (split_list : list (String * String))
          := List.Forall (@split_correctT str1) split_list.

        Definition split_list_completeT
                   valid1 valid2
                   (str : String) (pf : str ≤s fst p0)
                   (split_list : list (String * String))
                   (prod : production CharType)
          := match prod return Type with
               | nil => True
               | it::its => ({ s1s2 : String * String
                                      & (fst s1s2 ++ snd s1s2 =s str)
                                        * (minimal_parse_of_item _ G initial_names_data is_valid_name remove_name valid1 (fst s1s2) it)
                                        * (minimal_parse_of_production _ G initial_names_data is_valid_name remove_name valid2 (snd s1s2) its) }%type)
                            -> ({ s1s2 : String * String
                                         & (In s1s2 split_list)
                                           * (minimal_parse_of_item _ G initial_names_data is_valid_name remove_name valid1 (fst s1s2) it)
                                           * (minimal_parse_of_production _ G initial_names_data is_valid_name remove_name valid2 (snd s1s2) its) }%type)
             end.

        Lemma parse_production_sound
              (p : String * names_listT)
              (parse_name_sound : parse_name_soundT)
              (pf : prod_relation (ltof String Length) names_listT_R p p0)
              (prod : production CharType)
        : parse_production String initial_names_data split_string_for_production split_string_for_production_correct parse_name pf prod = true
          -> parse_of_production _ G (fst p) prod.
        Proof.
          change (forall str0 prod, split_list_correctT str0 (split_string_for_production str0 prod)) in split_string_for_production_correct.
          revert p parse_name_sound pf; induction prod;
          repeat match goal with
                   | _ => intro
                   | _ => progress simpl in *
                   | _ => progress subst
                   | _ => solve [ auto ]
                   | [ H : fold_right orb false (map _ _) = true |- _ ] => apply fold_right_orb_map_sig1 in H
                   | [ H : (_ || _)%bool = true |- _ ] => apply Bool.orb_true_elim in H
                   | [ H : (_ && _)%bool = true |- _ ] => apply Bool.andb_true_iff in H
                   | _ => progress destruct_head sumbool
                   | _ => progress destruct_head and
                   | _ => progress destruct_head sig
                   | _ => progress destruct_head Datatypes.prod
                   | _ => progress simpl in *
                   | _ => progress subst
                   | [ H : (_ =s _) = true |- _ ] => apply bool_eq_correct in H
                   | [ H : (_ =s _) = true |- _ ]
                     => let H' := fresh in
                        pose proof H as H';
                          apply bool_eq_correct in H';
                          progress subst
                 end.
          { constructor;
            [ eapply parse_item_sound; [..| eassumption ]; hnf
            | eapply (IHprod (_, _)); [..| eassumption ] ];
            repeat match goal with
                     | _ => progress unfold parse_name_soundT in *
                     | _ => eassumption
                     | _ => progress simpl in *
                     | [ |- appcontext[match dec ?E with _ => _ end] ] => case (dec E)
                     | [ |- appcontext[match dec ?E with _ => _ end] ] => destruct (dec E)
                     | _ => solve [ trivial ]
                     | [ |- forall _, _ ] => intro
                   end.
            eapply (parse_name_sound (_, _)). eassumption. }
        Defined.

        Lemma parse_production_complete
              (parse_name : names_listT -> parse_nameT)
              valid Pv
              (H_is_valid
               : forall name,
                   is_valid_name valid name = true
                   -> Pv valid name)
              (H_is_valid_init
               : forall name,
                   is_valid_name initial_names_data name = true
                   -> Pv initial_names_data name)
              (parse_name_complete : parse_name_completeT (parse_name valid) Pv valid)
              (parse_name_complete_init : parse_name_completeT (parse_name initial_names_data) Pv initial_names_data)
              (split_string_for_production_complete : forall valid1 valid2 str pf prod, @split_list_completeT valid1 valid2 str pf (split_string_for_production str prod) prod)
              (str : String) (pf : str ≤s str0)
              (prod : production CharType)
        : minimal_parse_of_production _ G initial_names_data is_valid_name remove_name valid str prod
          -> parse_production split_string_for_production split_string_for_production_correct (parse_name valid) pf prod = true.
        Proof.
          change (forall str0 prod, split_list_correctT str0 (split_string_for_production str0 prod)) in split_string_for_production_correct.
          revert valid H_is_valid parse_name_complete str pf; induction prod; [ admit | ]; simpl.
          repeat match goal with
                   | _ => intro
                   | _ => progress simpl in *
                   | _ => progress subst
                   | _ => solve [ auto ]
                   | [ H : fold_right orb false (map _ _) = true |- _ ] => apply fold_right_orb_map_sig1 in H
                   | [ H : (_ || _)%bool = true |- _ ] => apply Bool.orb_true_elim in H
                   | [ H : (_ && _)%bool = true |- _ ] => apply Bool.andb_true_iff in H
                   | [ H : minimal_parse_of_production _ _ _ _ _ _ _ nil |- _ ] => inversion_clear H
                   | [ |- (_ =s _) = true ] => apply bool_eq_correct
                   | _ => progress destruct_head_hnf and
                   | _ => progress destruct_head_hnf sig
                   | _ => progress destruct_head_hnf sigT
                   | _ => progress destruct_head_hnf Datatypes.prod
                   | [ H : (_ =s _) = true |- _ ] => apply bool_eq_correct in H
                   | [ H : (_ =s _) = true |- _ ]
                     => let H' := fresh in
                        pose proof H as H';
                          apply bool_eq_correct in H';
                          progress subst
                   | [ H : ?a -> ?b, H' : ?a |- _ ] => specialize (H H')
                   | [ |- fold_right orb false (map _ _) = true ] => apply fold_right_orb_map_sig2
                   | [ H : forall v : names_listT, @?a v -> @?b v |- _ ]
                     => pose proof (H valid); pose proof (H initial_names_data); clear H
                   | [ H : H_subT initial_names_data -> _ |- _ ]
                     => specialize (H (reflexivity _))
                   | [ H : ?s ≤s _ |- context[split_string_for_production_correct ?s ?p] ]
                     => specialize (fun a b p0 v1 p1 v2 p2
                                    => @split_string_for_production_complete v1 v2 s H p (existT _ (a, b) (p0, p1, p2)))
                   | [ H : forall a b, is_true (a ++ b =s _ ++ _) -> _ |- _ ]
                     => specialize (H _ _ (proj2 (@bool_eq_correct _ _ _ _) eq_refl))
                   | _ => progress destruct_head_hnf sumbool
                   | [ H : minimal_parse_of_production _ _ _ _ _ _ _ (_::_) |- _ ] => inversion H; clear H; subst
                 end.
          Print minimal_parse_of_production.
          Focus 4.
          match goal with
            | [ H : In (?s1, ?s2) (split_string_for_production ?str ?prod)
                |- { x : { s1s2 : _ | (fst s1s2 ++ snd s1s2 =s ?str) = true } | _ } ]
              => let H' := constr:(@Forall_forall1_transparent _ _ _ (@split_string_for_production_correct str prod) _ H) in
                 refine (exist _ (exist _ (s1, s2) H') _);
                   simpl in *
          end;
          repeat match goal with
                   | _ => split
                   | [ |- (_ && _)%bool = true ] => apply Bool.andb_true_iff
                   | [ |- In _ (combine_sig _) ] => apply In_combine_sig
                   | [ IHprod : _ |- _ ] => eapply IHprod; eassumption
                 end.
          Focus 2.
          eapply H.
          eassumption.
          eauto.
          match goal with
            | [ H : minimal_parse_of_item _ _ _ _ _ _ _ _ |- _ ]
              => inversion H; subst
          end;
          try solve [ repeat repeat match goal with
                                      | [ |- parse_item _ _ _ _ = true ]
                                        => eapply parse_item_complete
                                      | [ |- minimal_parse_of_item _ _ _ _ _ _ _ _ ] => solve [ constructor ]
                                      | _ => assumption
                                      | [ |- str_matches_name_completeT _ (parse_name valid _ _) _ _ ]
                                        => hnf in parse_name_complete |- *; apply parse_name_complete
                                    end ].
          { match goal with
                   | [ |- parse_item _ _ _ _ = true ]
                     => eapply parse_item_complete
            end.
            match goal with

                                      | [ |- minimal_parse_of_item _ _ _ _ _ _ _ _ ] => solve [ constructor ]
                                      | _ => assumption

                                    end.
          assumption.
          2:eauto.


            Focus 2.
            hnf in parse_name_complete |- *.
            apply parse_name_complete.
            assumption.
 [..| eassumption ];
                     try unfold H_subT; simpl;
                     try eassumption; try reflexivity;
                     hnf in parse_name_complete |- *;
                     try solve [ intros ??; apply parse_name_complete; eauto
                               | intros ??; apply parse_name_complete_init; eauto
                               | constructor ].
              end.
        Qed.
      End production.

      Section production_ext.
        Lemma parse_production_ext
              (str0 : String)
              (parse_name1 parse_name2 : forall (str : String),
                                                         str ≤s str0
                                                         -> string
                                                         -> bool)
              (str : String) (pf : str ≤s str0) (prod : production CharType)
              (ext : forall str' pf' name', parse_name1 str' pf' name'
                                                   = parse_name2 str' pf' name')
        : parse_production split_string_for_production split_string_for_production_correct parse_name1 pf prod
          = parse_production split_string_for_production split_string_for_production_correct parse_name2 pf prod.
        Proof.
          revert str pf.
          induction prod as [|? ? IHprod]; simpl; intros; try reflexivity; [].
          f_equal.
          apply map_ext; intros.
          apply f_equal2; [ apply parse_item_ext | apply IHprod ].
          intros; apply ext.
        Qed.
      End production_ext.

      Section productions.
        Section step.
          Variable str0 : String.

          Local Ltac parse_name_step_t :=
            repeat match goal with
                     | _ => intro
                     | [ H : (_ || _)%bool = true |- _ ] => apply Bool.orb_true_elim in H
                     | [ H : (_ && _)%bool = true |- _ ] => apply Bool.andb_true_iff in H
                     | [ |- (_ || _)%bool = true ] => apply Bool.orb_true_iff
                     | [ |- (_ =s _) = true ] => apply bool_eq_correct
                     | [ H : (_ =s _) = true |- _ ] => apply bool_eq_correct in H
                     | _ => progress destruct_head_hnf sumbool
                     | _ => progress destruct_head_hnf and
                     | _ => progress destruct_head_hnf sig
                     | _ => progress destruct_head_hnf sigT
                     | _ => progress destruct_head_hnf Datatypes.prod
                     | _ => progress simpl in *
                     | _ => progress subst
                     | [ H : parse_of _ _ _ nil |- _ ] => solve [ inversion H ]
                     | [ H : parse_of _ _ _ (_::_) |- _ ] => inversion H; clear H; subst
                     | [ H : minimal_parse_of _ _ _ _ _ _ _ nil |- _ ] => solve [ inversion H ]
                     | [ H : minimal_parse_of _ _ _ _ _ _ _ (_::_) |- _ ] => inversion H; clear H; subst
                     | [ H : parse_production _ _ _ _ _ = true |- _ ] => apply parse_production_sound in H; try eassumption; []
                     | _ => solve [ eauto ]
                   end.


          (** To parse as a given list of [production]s, we must parse as one of the [production]s. *)
          Lemma parse_name_step_sound
                (parse_name : forall (str : String) (pf : str ≤s str0), string -> bool)
                (parse_name_sound : parse_name_soundT parse_name)
                (str : String) (pf : str ≤s str0) (name : string)
          : parse_name_step G split_string_for_production split_string_for_production_correct parse_name pf name = true
            -> parse_of_item _ G str (NonTerminal _ name).
          Proof.
            unfold parse_name_step.
            intro H'; constructor; revert H'.
            case (Lookup G name); [ simpl; intro; congruence | ].
            intros prod prods; revert prod; simpl.
            induction prods; simpl; auto; intros.
            { parse_name_step_t. }
            { parse_name_step_t.
              apply ParseTail.
              apply IHprods; clear IHprods.
              parse_name_step_t. }
          Defined.

          Lemma parse_name_step_complete
                (parse_name : names_listT -> forall (str : String) (pf : str ≤s str0), string -> bool)
                valid Pv
                (H_is_valid_rem
                 : forall name name' : string,
                     is_valid_name (remove_name valid name) name' = true ->
                     Pv (remove_name valid name) name')
                (H_is_valid_init
                 : forall name : string,
                     is_valid_name initial_names_data name = true ->
                     Pv initial_names_data name)
                (parse_name_complete : forall name, parse_name_completeT (parse_name valid) Pv (remove_name valid name))
                (parse_name_complete_init : parse_name_completeT (parse_name initial_names_data) Pv initial_names_data)
                (split_string_for_production_complete : forall valid1 valid2 str pf prod, @split_list_completeT str0 valid1 valid2 str pf (split_string_for_production str prod) prod)
                (str : String) (pf : str ≤s str0) (name : string)
          : minimal_parse_of_item _ G initial_names_data is_valid_name remove_name valid str (NonTerminal _ name)
            -> parse_name_step G split_string_for_production split_string_for_production_correct (parse_name valid) pf name = true.
          Proof.
            unfold parse_name_step.
            intro H; inversion_clear H.
            let H := match goal with H : minimal_parse_of _ _ _ _ _ _ _ _ |- _ => constr:H end in
            revert H.
            case (Lookup G name); simpl;
            [ solve [ intro H; inversion H ]
            | ].
            intros prod prods; revert prod.
            induction prods; simpl; auto.
            { parse_name_step_t.
              left; eapply parse_production_complete with (Pv := Pv); [..| eassumption ];
              try solve [ eassumption | eauto ]. }
            { parse_name_step_t;
              match goal with
                | [ H : forall prod, minimal_parse_of _ _ _ _ _ _ ?s (prod::_) -> _,
                      H' : minimal_parse_of_production _ _ _ _ _ _ ?s ?prod |- _ ]
                  => specialize (H prod (MinParseHead _ H'))
                | [ H : forall prod, minimal_parse_of _ _ _ _ _ _ ?s (prod::?prods) -> _,
                      H' : minimal_parse_of _ _ _ _ _ _ ?s ?prods |- _ ]
                  => specialize (fun prod => H prod (MinParseTail _ H'))
              end;
              parse_name_step_t;
              solve [ right; parse_name_step_t]. }
          Qed.
        End step.

        Section step_extensional.
          Lemma parse_name_step_ext (str0 : String)
                (parse_name1 parse_name2 : forall (str : String)
                                                  (pf : str ≤s str0),
                                             string -> bool)
                (str : String) (pf : str ≤s str0) (name : string)
                (ext : forall str' pf' name', parse_name1 str' pf' name'
                                              = parse_name2 str' pf' name')
          : parse_name_step G split_string_for_production split_string_for_production_correct parse_name1 pf name
            = parse_name_step G split_string_for_production split_string_for_production_correct parse_name2 pf name.
          Proof.
            unfold parse_name_step.
            f_equal.
            apply map_ext; intros.
            apply parse_production_ext; auto.
          Qed.
        End step_extensional.

        (** TODO: move this elsewhere *)
        Lemma or_to_sumbool (s1 s2 : String) (f : String -> nat)
              (H : f s1 < f s2 \/ s1 = s2)
        : {f s1 < f s2} + {s1 = s2}.
        Proof.
          case_eq (s1 =s s2).
          { intro H'; right; apply bool_eq_correct in H'; exact H'. }
          { intro H'; left; destruct H; trivial.
            apply bool_eq_correct in H.
            generalize dependent (s1 =s s2)%string_like; intros; subst.
            discriminate. }
        Qed.

        (** TODO: move this elsewhere *)
        Lemma if_ext {T} (b : bool) (f1 f2 : b = true -> T true) (g1 g2 : b = false -> T false)
              (ext_f : forall H, f1 H = f2 H)
              (ext_g : forall H, g1 H = g2 H)
        : (if b as b' return (b = b' -> T b') then f1 else g1) eq_refl
          = (if b as b' return (b = b' -> T b') then f2 else g2) eq_refl.
        Proof.
          destruct b; auto.
        Defined.

        Section wf.
          Lemma parse_name_or_abort_sound
                (p : String * names_listT) (str : String)
                (pf : str ≤s fst p)
                (name : string)
          : parse_name_or_abort G initial_names_data is_valid_name remove_name
                                remove_name_dec ntl_wf split_string_for_production
                                split_string_for_production_correct
                                p pf name
            = true
            -> parse_of_item _ G str (NonTerminal _ name).
          Proof.
            unfold parse_name_or_abort.
            revert str pf name.
            let Acca := match goal with |- context[@Fix3 _ _ _ _ _ ?Rwf _ _ ?a _ _ _] => constr:(Rwf a) end in
            induction (Acca) as [? ? IHr];
              intros str pf name.
            rewrite Fix3_eq.
            { match goal with
                | [ |- context[match dec ?E with _ => _ end] ] => destruct (dec E) as [Hdec|Hdec]
              end; [ | solve [ auto ] ].
              match goal with
                | [ |- context[match lt_dec ?a ?b with _ => _ end] ] => destruct (lt_dec a b) as [Hlt|Hlt]
              end.
              { apply parse_name_step_sound; try assumption; simpl.
                hnf.
                intros str0 pf0 name0 H'; eapply IHr;
                try first [ exact H' | eassumption ].
                left; assumption. }
              { intros.
                hnf in pf.
                apply or_to_sumbool in pf.
                destruct pf as [ pf | pf ]; [ exfalso; hnf in *; solve [ auto ] | subst ].
                eapply parse_name_step_sound; try eassumption.
                hnf.
                intros str0 pf0 name0 H'; eapply IHr;
                try first [ exact H' | eassumption ].
                right; split; trivial; simpl.
                apply remove_name_dec; assumption. } }
            { repeat match goal with
                       | _ => intro
                       | _ => reflexivity
                       | [ |- context[match ?E with _ => _ end] ] => destruct E
                       | [ H : _ |- _ ] => rewrite H; reflexivity
                       | _ => apply parse_name_step_ext; auto
                       | _ => apply (@if_ext (fun _ => bool)); intros
                     end. }
          Defined.

          Lemma parse_name_or_abort_complete
                Pv
                (p : String * names_listT) (str : String)
                (H_is_valid
                 : forall name : string,
                     is_valid_name (snd p) name = true ->
                     Pv (snd p) name)
                (H_is_valid_rem
                 : forall name name' : string,
                     is_valid_name (remove_name (snd p) name) name' = true ->
                     Pv (remove_name (snd p) name) name')
                (H_is_valid_init
                 : forall name : string,
                     is_valid_name initial_names_data name = true ->
                     Pv initial_names_data name)
                (H_is_valid_init_rem
                 : forall name name' : string,
                     is_valid_name (remove_name initial_names_data name) name' = true ->
                     Pv (remove_name initial_names_data name) name')
                (Hv_expand
                 : forall str name' valid,
                     Pv valid name'
                     -> minimal_parse_of_item
                          String G initial_names_data
                          is_valid_name remove_name valid str
                          (NonTerminal _ name')
                     -> minimal_parse_of_item
                          String G initial_names_data
                          is_valid_name remove_name initial_names_data str
                          (NonTerminal _ name'))
                (Hv_valid_init : forall ls name', Pv ls name' -> Pv initial_names_data name')
                (split_string_for_production_complete : forall valid0 valid1 str0 pf prod, @split_list_completeT str valid0 valid1 str0 pf (split_string_for_production str0 prod) prod)
                (pf : str ≤s fst p)
                (name : string)
                (Hv : Pv (snd p) name)
                (*(H_init : Pv initial_names_data name)*)
          (*(H_prods : is_valid_name (snd p) (prod::prods) = true)*)
          : minimal_parse_of_item _ G initial_names_data is_valid_name remove_name (snd p) str (NonTerminal _ name)
            -> parse_name_or_abort G initial_names_data is_valid_name remove_name
                                   remove_name_dec ntl_wf split_string_for_production
                                   split_string_for_production_correct
                                   p pf name
               = true.
          Proof.
            unfold parse_name_or_abort.
            revert str split_string_for_production_complete pf name Hv (*H_init*).
            let Acca := match goal with |- context[@Fix3 _ _ _ _ _ ?Rwf _ _ ?a _ _ _] => constr:(Rwf a) end in
            induction (Acca) as [? ? IHr];
              intros str split_string_for_production_complete pf name Hv (*H_init*).
            rewrite Fix3_eq;
              [
              | repeat match goal with
                       | _ => intro
                       | _ => reflexivity
                       | [ |- context[match ?E with _ => _ end] ] => destruct E
                       | [ H : _ |- _ ] => rewrite H; reflexivity
                       | _ => apply parse_name_step_ext; auto
                       | _ => apply (@if_ext (fun _ => bool)); intros
                     end ];
              [].
            { match goal with
                | [ |- context[if dec ?E then _ else _] ] => destruct (dec E)
              end.
              { match goal with
                  | [ |- context[if lt_dec ?a ?b then _ else _] ] => destruct (lt_dec a b)
                end.
                { eapply parse_name_step_complete;
                  try solve [ eassumption | instantiate; intros; eauto ]; hnf; [].
                  intros valid str0 pf0 name0 H'; simpl.
                  intro mp.
                  intro; eapply IHr;
                  simpl;
                  try solve [ exact H'
                            | eassumption
                            | reflexivity
                            | simpl in *; trivial
                            | eapply Hv_expand; eassumption
                            | eapply Hv_valid_init; eassumption ].
                  { left; assumption. }
                  { intros; apply split_string_for_production_complete.
                    etransitivity; eassumption. } }
                { intros.
                  hnf in pf.
                  apply or_to_sumbool in pf.
                  destruct pf as [ pf | pf ]; [ exfalso; hnf in *; solve [ auto ] | subst ].

                  eapply parse_name_step_complete;
                    try solve [ eassumption
                              | instantiate; intros; trivial
                              | instantiate; simpl; eapply Hv_expand; eauto ];
                    hnf; simpl; [].
                  intros valid v_opts str0 pf0 name0 H'; simpl.
                  intro mp.

                  eapply IHr;
                    simpl;
                    try solve [ exact H'
                              | eassumption
                              | simpl; trivial
                              | intros; eapply H_is_valid_rem; eassumption
                              | intros; eapply H_is_valid_init_rem; eassumption ].
                  { right; split; trivial; simpl.
                    apply remove_name_dec; assumption. }
                  { admit. }
                  { intros; apply split_string_for_production_complete.
                    etransitivity; eassumption. }
                  { admit. }
                  { destruct_head sum; destruct_head sig; subst.
                    Focus 2.
 } }
              { (** INTERESTING CASE HERE - need to show that if not
                      [is_valid_name], then we can't have a
                      parse tree. *)
                intro H'; exfalso.
                inversion_clear H'.
                congruence. } }
          Defined.

          Lemma parse_name_sound
                (str : String) (prods : productions CharType)
          : parse_name _ G initial_names_data is_valid_name remove_name
                              remove_name_dec ntl_wf split_string_for_production
                              split_string_for_production_correct
                              str prods
            = true
            -> parse_of _ G str prods.
          Proof.
            unfold parse_name, parse_name_or_abort.
            destruct prods; [ solve [ auto ] | ].
            apply parse_name_or_abort_helper_sound.
          Defined.

          Lemma parse_name_complete
                valid
                (str : String)
                (split_string_for_production_complete : forall valid0 valid1 str0 pf prod, @split_list_completeT str valid0 valid1 str0 pf (split_string_for_production str0 prod) prod)
                (prods : productions CharType)
          : minimal_parse_of _ G initial_names_data is_valid_name remove_name valid str prods
            -> parse_name _ G initial_names_data is_valid_name remove_name
                                 remove_name_dec ntl_wf split_string_for_production
                                 split_string_for_production_correct
                                 str prods
               = true.
          Proof.
            unfold parse_name, parse_name_or_abort.
            destruct prods; [ solve [ intro H'; inversion H' ] | ].
            apply parse_name_or_abort_helper_complete; try assumption.
          Defined.
        End wf.
      End productions.
    End parts.
  End general.
End sound.

Section brute_force_spliter.
  Lemma make_all_single_splits_complete_helper
  : forall (str : string_stringlike)
           (s1s2 : string_stringlike * string_stringlike),
      fst s1s2 ++ snd s1s2 =s str -> In s1s2 (make_all_single_splits str).
  Proof.
    intros str [s1 s2] H.
    apply bool_eq_correct in H; subst.
    revert s2.
    induction s1; simpl in *.
    { intros.
      destruct s2; left; reflexivity. }
    { intros; right.
      refine (@in_map _ _ _ _ (s1, s2) _).
      auto. }
  Qed.
Check split_list_completeT.
  Lemma make_all_single_splits_complete
  : forall G names_listT initial_names_data is_valid_name remove_name str0 valid0 valid1 str pf prod, @split_list_completeT _ string_stringlike G names_listT initial_names_data is_valid_name remove_name str0 valid0 valid1 str pf (@make_all_single_splits str) prod.
  Proof.
    intros; hnf.
    destruct prod; trivial.
    intros [ s1s2 [ [ p1 p2 ] p3 ] ].
    exists s1s2.
    abstract (
        repeat split; try assumption;
        apply make_all_single_splits_complete_helper;
        assumption
      ).
  Defined.
End brute_force_spliter.

Section brute_force_make_parse_of.
  Variable G : grammar Ascii.ascii.

  Definition brute_force_make_parse_of_sound
             (str : @String Ascii.ascii string_stringlike)
             (prods : productions Ascii.ascii)
  : brute_force_make_parse_of G str prods = true -> parse_of _ G str prods.
  Proof.
    unfold brute_force_make_parse_of.
    apply parse_name_sound.
  Defined.

  Definition brute_force_make_parse_of_complete
             valid
             (str : @String Ascii.ascii string_stringlike)
             (prods : productions Ascii.ascii)
  : minimal_parse_of _ G (Valid_nonterminals G) (rdp_list_is_valid_name Ascii.ascii_dec) (rdp_list_remove_name Ascii.ascii_dec) valid str prods
    -> brute_force_make_parse_of G str prods = true.
  Proof.
    unfold brute_force_make_parse_of; simpl; intro.
    eapply parse_name_complete; try eassumption.
    apply make_all_single_splits_complete.
  Defined.
End brute_force_make_parse_of.
