(** * Specialization of the dependently typed parser to minimal parse trees *)
Require Import Coq.Lists.List Coq.Program.Program Coq.Program.Wf Coq.Arith.Wf_nat Coq.Arith.Compare_dec Coq.Classes.RelationClasses Coq.Strings.String.
Require Import Coq.omega.Omega.
Require Import ParsingParses.Parsers.ContextFreeGrammar ParsingParses.Parsers.DependentlyTyped ParsingParses.Parsers.MinimalParse ParsingParses.Parsers.BooleanBaseTypes ParsingParses.Parsers.BaseTypes.
Require Import ParsingParses.Common ParsingParses.Common.Wf.

Set Implicit Arguments.

Local Open Scope string_like_scope.

Local Coercion is_true : bool >-> Sortclass.

Section recursive_descent_parser.
  Context (CharType : Type)
          (String : string_like CharType)
          (G : grammar CharType).
  Context {methods : @parser_computational_dataT _ String}
          {strdata : @parser_computational_strdataT _ String G _}.

  Section minimal.
    Local Ltac t' :=
      idtac;
      match goal with
        | _ => intro
        | _ => progress hnf in *
        | _ => progress simpl in *
        | _ => progress subst_body
        | _ => progress subst
        | [ H : ?A -> ?B, H' : ?A |- _ ] => specialize (H H')
        | [ H : ?A -> ?B |- _ ] => let A' := (eval hnf in A) in
                                   progress change (A' -> B) in H
        | _ => progress destruct_head StringWithSplitState
        | _ => progress destruct_head False
        | [ H : context[?x =s ?x] |- _ ]
          => rewrite (proj2 (bool_eq_correct _ x x) eq_refl) in H
        | [ H : true = false |- _ ] => exfalso; discriminate
        | _ => progress inversion_head @minimal_parse_of_item
        | _ => progress inversion_head @minimal_parse_of_production
      end.

    Local Ltac t := repeat t'.

    Section parts.
      Section common.
        Section types.
          Context (str0 : String)
                  (valid : nonterminals_listT).

          Definition T_nonterminal_success (nonterminal : string) (str : StringWithSplitState String (split_stateT str0 valid (include_nonterminal _ nonterminal))) : Type
            := minimal_parse_of_nonterminal (G := G) str0 valid str nonterminal.
          Definition T_nonterminal_failure (nonterminal : string) str : Type
            := T_nonterminal_success nonterminal str -> False.

          Definition T_item_success (it : item CharType) (str : StringWithSplitState String (split_stateT str0 valid it)) : Type
            := minimal_parse_of_item (G := G) str0 valid str it.
          Definition T_item_failure (it : item CharType) str : Type
            := T_item_success it str -> False.

          Definition T_production_success (prod : production CharType) (str : StringWithSplitState String (split_stateT str0 valid prod)) : Type
            := minimal_parse_of_production (G := G) str0 valid str prod.

          Definition T_production_failure (prod : production CharType) str : Type
            := T_production_success prod str -> False.

          Definition T_productions_success (prods : productions CharType) (str : StringWithSplitState String (split_stateT str0 valid prods)) : Type
            := minimal_parse_of (G := G) str0 valid str prods.

          Definition T_productions_failure (prods : productions CharType) str : Type
            := T_productions_success prods str -> False.
        End types.

        Global Instance minimal_parser_dependent_types_success_data'
        : @parser_dependent_types_success_dataT' _ String _
          := { T_nonterminal_success := T_nonterminal_success;
               T_item_success := T_item_success;
               T_production_success := T_production_success;
               T_productions_success := T_productions_success }.

        Global Instance minimal_parser_dependent_types_success_data
        : @parser_dependent_types_success_dataT _ String
          := { stypes' := minimal_parser_dependent_types_success_data' }.

        Global Instance minimal_parser_dependent_types_failure_data'
        : @parser_dependent_types_failure_dataT' _ String _
          := { T_nonterminal_failure := T_nonterminal_failure;
               T_item_failure := T_item_failure;
               T_production_failure := T_production_failure;
               T_productions_failure := T_productions_failure }.

        Global Instance minimal_parser_dependent_types_data
        : @parser_dependent_types_dataT _ String
          := { stypes := minimal_parser_dependent_types_success_data;
               ftypes' := minimal_parser_dependent_types_failure_data' }.

        Lemma H_prod_split'_helper
              (str0 : String)
              (valid : nonterminals_listT)
              (it : item CharType) (its : production CharType)
              (str : StringWithSplitState String (split_stateT str0 valid it))
              (strs : StringWithSplitState String (split_stateT str0 valid its))
              (p_it : minimal_parse_of_item (G := G) str0 valid str it)
              (p_its : minimal_parse_of_production (G := G) str0 valid strs its)
              (ls : list
                      (StringWithSplitState String (split_stateT str0 valid it) *
                       StringWithSplitState String (split_stateT str0 valid its)))
              (Hin : In (str, strs) ls)
              (H : fold_right
                     Datatypes.prod
                     unit
                     (map
                        (fun s1s2 =>
                           let s1 := fst s1s2 in
                           let s2 := snd s1s2 in
                           ((@T_item_failure str0 valid it s1 * @T_production_failure str0 valid its s2)
                            + (@T_item_success str0 valid it s1 * @T_production_failure str0 valid its s2)
                            + (@T_item_failure str0 valid it s1 * @T_production_success str0 valid its s2))%type)
                        ls))
        : False.
        Proof.
          induction ls; simpl in *; trivial; [].
          destruct_head or; subst;
          destruct_head prod; eauto; [].
          destruct_head sum; destruct_head prod;
          unfold T_item_failure, T_item_success, T_production_failure, T_production_success in *;
          eauto.
        Qed.

        Definition H_prod_split'
                   (str0 : String)
                   (valid : nonterminals_listT)
                   it its
                   (str : StringWithSplitState String (split_stateT str0 valid (it::its : production CharType)))
                   pf
                   (split_list_complete : @split_list_completeT _ _ G _ str0 valid it its str pf (split_string_for_production str0 valid it its str))
        : @split_string_lift_T _ String _ _ str0 valid it its str (split_string_for_production str0 valid it its str).
        Proof.
          clear -split_list_complete.
          intros H pf' H'; hnf in H', split_list_complete.
          destruct str as [str st]; simpl in *.
          inversion H'; clear H'; subst.
          specialize (fun s1 s2 b
                      => split_list_complete
                           (existT _ (s1, s2) b));
            simpl in *.
          let p_it := hyp_with_head @minimal_parse_of_item in
          let p_its := hyp_with_head @minimal_parse_of_production in
          specialize (fun pf => split_list_complete _ _ (pf, p_it, p_its)).
          repeat match goal with
                   | [ H : ?T -> ?A |- _ ]
                     => let H' := fresh in
                        assert (H' : T) by (apply bool_eq_correct; reflexivity);
                          specialize (H H'); clear H'
                   | _ => progress destruct_sig
                 end.
          eapply H_prod_split'_helper; eassumption.
        Qed.

        Hint Constructors minimal_parse_of minimal_parse_of_nonterminal minimal_parse_of_production minimal_parse_of_item unit : minimal_instance_db.

        Local Ltac t'' :=
          first [ intro
                | progress hnf in *
                | progress eauto with minimal_instance_db
                | progress destruct_head @StringWithSplitState
                | progress simpl in *
                | progress subst
                | match goal with H : (_ =s _) = true |- _ => apply bool_eq_correct in H end ].

        Local Ltac t' :=
          first [ t''
                | congruence
                | omega
                | match goal with H : (?x =s ?x) = false |- _ => erewrite (proj2 (bool_eq_correct _ _ _)) in H by reflexivity end ].

        Local Ltac t :=
          repeat intro;
          match goal with
            | [ |- False ]
              => abstract (
                     subst_body;
                     repeat t';
                     do 2 try inversion_one_head_hnf @minimal_parse_of_nonterminal;
                     repeat t';
                     do 2 try inversion_one_head_hnf @minimal_parse_of_item;
                     repeat t';
                     do 2 try inversion_one_head_hnf @minimal_parse_of_production;
                     repeat t';
                     do 2 try inversion_one_head_hnf @minimal_parse_of;
                     repeat t'
                   )
            | _ => try solve [ repeat t'' ]
          end.

        Local Obligation Tactic := t.

        Global Program Instance minimal_parser_dependent_types_extra_success_data'
        : @parser_dependent_types_extra_success_dataT' _ String G _ _.

        Global Program Instance minimal_parser_dependent_types_extra_failure_data'
               (split_list_complete : forall str0 valid it its str pf, @split_list_completeT _ _ G _ str0 valid it its str pf (split_string_for_production str0 valid it its str))
        : @parser_dependent_types_extra_failure_dataT' _ String G _ _.
        Next Obligation.
          eapply H_prod_split'; eauto.
          Grab Existential Variables.
          assumption.
        Defined.

        Global Instance minimal_parser_dependent_types_extra_data split_list_complete
        : @parser_dependent_types_extra_dataT _ String G
          := { extra_failure_data := minimal_parser_dependent_types_extra_failure_data' split_list_complete;
               extra_success_data := minimal_parser_dependent_types_extra_success_data' }.
      End common.

      Definition minimal_parse_nonterminal
                 (split_list_complete
                  : forall str0 valid it its str pf,
                      @split_list_completeT _ _ G _ str0 valid it its str pf (split_string_for_production str0 valid it its str))
      : forall (nonterminal : string)
               (s : String)
               (st : split_stateT s _ (include_nonterminal _ nonterminal) s)
               (str := {| string_val := s ; state_val := st |}),
          sum (T_nonterminal_success str initial_nonterminals_data nonterminal str)
              (T_nonterminal_failure str initial_nonterminals_data nonterminal str)
        := @parse_nonterminal _ String G (minimal_parser_dependent_types_extra_data split_list_complete).
    End parts.
  End minimal.
End recursive_descent_parser.
