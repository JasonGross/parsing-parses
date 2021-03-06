(** * Specialization of the dependently typed parser to minimal parse trees, taking in parse trees *)
Require Import Coq.Lists.List Coq.Program.Program Coq.Program.Wf Coq.Arith.Wf_nat Coq.Arith.Compare_dec Coq.Classes.RelationClasses Coq.Strings.String.
Require Import Coq.omega.Omega.
Require Import ParsingParses.Parsers.ContextFreeGrammar ParsingParses.Parsers.DependentlyTyped ParsingParses.Parsers.MinimalParse.
Require Import ParsingParses.Parsers.WellFoundedParse ParsingParses.Parsers.ContextFreeGrammarProperties ParsingParses.Parsers.BaseTypes.
Require Import ParsingParses.Common ParsingParses.Common.Wf ParsingParses.Common.Le.

Set Implicit Arguments.

Local Open Scope string_like_scope.

Local Coercion is_true : bool >-> Sortclass.

Section recursive_descent_parser.
  Context (CharType : Type)
          (String : string_like CharType)
          (G : grammar CharType).
  Context {premethods : parser_computational_predataT}
          {rdata : @parser_removal_dataT' premethods}.
  Local Instance types_methods : @parser_computational_types_dataT _ String
    := { predata := premethods;
         split_stateT str0 valid g str := unit }.
  Variable orig_methods : @parser_computational_dataT' CharType String types_methods.

  Definition P (str0 : String) valid : String -> string -> Prop
    := fun str p =>
         sub_nonterminals_listT valid initial_nonterminals_data
         /\ is_valid_nonterminal
              (if lt_dec (Length str) (Length str0)
               then initial_nonterminals_data
               else valid)
              p = true.

  Lemma P_remove_impl {str0 valid str nonterminal nonterminal'}
        (H0 : nonterminal <> nonterminal')
        (H : P str0 valid str nonterminal')
  : P str0 (remove_nonterminal valid nonterminal) str nonterminal'.
  Proof.
    destruct_head_hnf and.
    repeat split; try assumption.
    { apply sub_nonterminals_listT_remove_2; assumption. }
    { destruct lt_dec; try assumption.
      match goal with
        | [ |- ?b = true ] => case_eq b; try reflexivity
      end.
      intro H'; exfalso.
      apply remove_nonterminal_2 in H'.
      destruct H'; congruence. }
  Qed.

  Definition p_parse_item str0 valid s it
    := { p' : parse_of_item String G s it & Forall_parse_of_item (P str0 valid) p' }.
  Definition p_parse_production str0 valid s p
    := { p' : parse_of_production String G s p & Forall_parse_of_production (P str0 valid) p' }.
  Definition p_parse str0 valid s prods
    := { p' : parse_of String G s prods & Forall_parse_of (P str0 valid) p' }.
  Definition p_parse_nonterminal str0 valid s nonterminal
    := { p' : parse_of_item String G  s (NonTerminal _ nonterminal) & Forall_parse_of_item (P str0 valid) p' }.

  Definition mp_parse_item str0 valid str it
    := minimal_parse_of_item (String := String) (G := G) str0 valid str it.
  Definition mp_parse_production str0 valid str prod
    := minimal_parse_of_production (String := String) (G := G) str0 valid str prod.
  Definition mp_parse str0 valid str prods
    := minimal_parse_of (String := String) (G := G) str0 valid str prods.
  Definition mp_parse_nonterminal str0 valid str nonterminal
    := minimal_parse_of_nonterminal (String := String) (G := G) str0 valid str nonterminal.

  Definition split_parse_of_production {str0 valid str it its}
             (p : p_parse_production str0 valid str (it::its))
  : { s1s2 : String * String & (fst s1s2 ++ snd s1s2 =s str)
                               * p_parse_item str0 valid (fst s1s2) it
                               * p_parse_production str0 valid (snd s1s2) its }%type.
  Proof.
    destruct p as [p H]; revert p H.
    pattern (it :: its).
    match goal with
      | [ |- ?P ?ls ]
        => set (prods := ls);
          change it with (hd it prods);
          change its with (tl prods);
          assert (H' : ls = prods) by reflexivity;
          clearbody prods;
          simpl
    end.
    intro p.
    destruct p.
    { exfalso; clear -H'; abstract inversion H'. }
    { intro H''.
      eexists (_, _); simpl.
      repeat split; try match goal with H : _ |- _ => exists H end.
      { apply bool_eq_correct; reflexivity. }
      { exact (fst H''). }
      { exact (snd H''). } }
  Defined.

  Lemma split_parse_of_production_le1 {str0 valid str it its p}
  : fst (projT1 (@split_parse_of_production str0 valid str it its p)) ≤s str.
  Proof.
    etransitivity; [ eapply str_le1_append | right; apply bool_eq_correct ].
    exact (fst (fst (projT2 (split_parse_of_production p)))).
  Qed.

  Lemma split_parse_of_production_le2 {str0 valid str it its p}
  : snd (projT1 (@split_parse_of_production str0 valid str it its p)) ≤s str.
  Proof.
    etransitivity; [ eapply str_le2_append | right; apply bool_eq_correct ].
    exact (fst (fst (projT2 (split_parse_of_production p)))).
  Qed.

  Local Instance types_methods' : @parser_computational_types_dataT _ String
    := { predata := premethods;
         split_stateT str0 valid g s
         := option (match g return Type with
                      | include_item it => p_parse_item str0 valid s it
                      | include_production p => p_parse_production str0 valid s p
                      | include_productions prods => p_parse str0 valid s prods
                      | include_nonterminal nonterminal => p_parse_nonterminal str0 valid s nonterminal
                    end) }.

  Local Instance methods' : @parser_computational_dataT' _ String types_methods'
    := { split_string_for_production str0 valid it its s
          := let orig_splits := map (fun s1s2 =>
                                       ({| string_val := string_val (fst s1s2);
                                           state_val := None |},
                                        {| string_val := string_val (snd s1s2);
                                           state_val := None |}))
                                    (@split_string_for_production _ _ _ orig_methods str0 valid it its {| string_val := string_val s ; state_val := tt |}) in
             match state_val s with
               | None => orig_splits
               | Some st => let st' := split_parse_of_production st in
                            ({| string_val := fst (projT1 st') ; state_val := Some (snd (fst (projT2 st'))) |},
                             {| string_val := snd (projT1 st') ; state_val := Some (snd (projT2 st')) |})::nil
             end }.
  Proof.
    intros; subst_body; simpl in *.
    abstract (
        destruct_head @StringWithSplitState;
        destruct_head option;
        repeat match goal with
                 | _ => progress simpl in *
                 | _ => progress unfold compose
                 | [ |- Forall _ (?f _ _ _) ] => unfold f
                 | [ |- Forall _ nil ] => constructor
                 | [ |- Forall _ (_::_) ] => constructor
                 | [ |- Forall _ (map _ _) ] => apply Forall_map
                 | _ => refine (split_string_for_production_correct _ _ _ _ {| state_val := _ |})
                 | _ => exact (fst (fst (projT2 (split_parse_of_production _))))
               end
      ).
  Defined.

  Definition parse_of__of__parse_of_item_lt' {str0 valid str nonterminal}
             (pf : Length str < Length str0)
             (p : p_parse_nonterminal str0 valid str nonterminal)
  : P str0 valid str nonterminal * p_parse str initial_nonterminals_data str (Lookup G nonterminal).
  Proof.
    refine (match projT1 p as p' in parse_of_item _ _ str' it'
                  return match it' with
                           | Terminal _ => True
                           | NonTerminal nonterminal' => Length str' < Length str0 -> Forall_parse_of_item (P str0 valid) p' -> P str0 valid str' nonterminal' * p_parse str' initial_nonterminals_data str' (Lookup G nonterminal')
                         end
            with
              | ParseTerminal _ => I
              | ParseNonTerminal _ _ p' => fun pf' H' => (fst H', existT _ p' (expand_forall_parse_of _ _ (snd H')))
            end pf (projT2 p)).
    clear -pf'; unfold P in *; simpl;
    abstract (intros ??; do 2 edestruct lt_dec; intuition).
  Defined.
  Definition parse_of__of__parse_of_item_lt {str0 valid str nonterminal} pf p
    := snd (@parse_of__of__parse_of_item_lt' str0 valid str nonterminal pf p).

  Definition deloop_right str0 valid str nonterminal
    := p_parse str0 (remove_nonterminal valid nonterminal) str (Lookup G nonterminal).

  Definition deloop_onceT
    := forall str0 valid str nonterminal prods
              (p : parse_of String G str prods)
              (pf : str = str0 :> String)
              (H : Forall_parse_of (P str0 valid) p),
         p_parse str0 (remove_nonterminal valid nonterminal) str prods
         + deloop_right str0 valid str nonterminal.

  Definition deloop_once_productionT
    := forall str0 valid str nonterminal prod
              (p : parse_of_production String G str prod)
              (pf : str = str0 :> String)
              (H : Forall_parse_of_production (P str0 valid) p),
         p_parse_production str0 (remove_nonterminal valid nonterminal) str prod
         + deloop_right str0 valid str nonterminal.

  Definition deloop_once_item'
             (deloop_once : deloop_onceT)
             {str0 valid str nonterminal}
             {it}
             (p : parse_of_item String G str it)
             (pf : str = str0 :> String)
             (H : Forall_parse_of_item (P str0 valid) p)
  : p_parse_item str0 (remove_nonterminal valid nonterminal) str it
    + deloop_right str0 valid str nonterminal.
  Proof.
    destruct p as [ | nonterminal' str'' p' ].
    { exact (inl (existT _ (ParseTerminal _ _ _) tt)). }
    { refine (if string_dec nonterminal nonterminal'
              then inr match @deloop_once _ _ _ nonterminal' _ p' pf (snd H) with
                         | inl p''' => _
                         | inr ret => _
                       end
              else match @deloop_once _ _ _ nonterminal _ p' pf (snd H) with
                     | inl p''' => inl (existT _ (ParseNonTerminal _ (projT1 p''')) (P_remove_impl _ (fst H), projT2 p'''))
                     | inr ret => inr ret
                   end);
      clear deloop_once;
      solve [ assumption
            | subst; assumption ]. }
  Defined.

  Definition deloop_once'
             (deloop_once : deloop_onceT)
             (deloop_once_production : deloop_once_productionT)
  : deloop_onceT.
  Proof.
    intros str0 valid str nonterminal pats p pf H.
    destruct p as [ str' pat' pats' p' | str' pat' pats' p' ].
    { refine match deloop_once_production str0 valid str' nonterminal _ p' pf H with
               | inl ret => inl (existT _ (ParseHead pats' (projT1 ret)) (projT2 ret))
               | inr ret => inr ret
             end. }
    { refine match deloop_once str0 valid str' nonterminal _ p' pf H with
               | inl ret => inl (existT _ (ParseTail _ (projT1 ret)) (projT2 ret))
               | inr ret => inr ret
             end. }
  Defined.

  Local Ltac deloop_t :=
    repeat match goal with
             | _ => assumption
             | _ => intro
             | [ H : ?x = ?y |- _ ] => subst x
             | [ H : ?x = ?y |- _ ] => subst y
             | [ H : _ ≤s _ |- _ ] => destruct H
             | _ => progress simpl in *
             | [ H : _ |- _ ] => rewrite Length_Empty in H
             | _ => rewrite Length_Empty
             | [ H : _ < 0 |- _ ] => destruct (Lt.lt_n_0 _ H)
             | _ => progress destruct_head and
             | [ |- _ /\ _ ] => split
             | [ H : sub_nonterminals_listT _ _ |- is_valid_nonterminal _ _ = true ]
               => (apply H; eapply sub_nonterminals_listT_remove; eassumption)
             | [ H : ~0 < ?n |- _ ]
               => (let H' := fresh in
                   destruct (zerop n) as [ | H' ]; [ clear H | destruct (H H') ])
             | [ H : Length _ = 0 |- _ ] => apply Empty_Length in H
             | [ H : ?x <> ?x |- _ ] => destruct (H eq_refl)
             | [ H : context[Length (_ ++ _)] |- _ ] => rewrite <- Length_correct in H
             | [ H : ~_ < _ + _ |- _ ]
               => unique pose proof (proj1 (not_lt_plus H))
             | [ H : ~_ < _ + _ |- _ ]
               => unique pose proof (proj2 (not_lt_plus H))
             | [ H : ?T, H' : ~?T |- _ ] => destruct (H' H)
             | [ H : ~ ?a < ?a + _ |- _ ] => apply not_lt_add_r in H
             | [ H : ~ ?a < _ + ?a |- _ ] => apply not_lt_add_l in H
           end.

  Definition deloop_once_production'
             (deloop_once : deloop_onceT)
             (deloop_once_production : deloop_once_productionT)
  : deloop_once_productionT.
  Proof.
    intros str0 valid str nonterminal pat p pf H.
    destruct p as [ | str' pat' strs' pats' p' p'' ].
    { refine (inl (existT _ (ParseProductionNil _ _) tt)). }
    { (** We must discriminate based on whether or not [str] has already gotten shorter *)
      destruct (stringlike_dec str' (Empty _)) as [e|e], (stringlike_dec strs' (Empty _)) as [e'|e'];
      try (assert (pf0 : str' = str0)
            by (clear -pf e'; abstract (subst strs'; rewrite ?RightId, ?LeftId in pf; exact pf));
           pose proof (@deloop_once_item' (deloop_once) str0 valid _ nonterminal pat' p' pf0 (fst H)) as deloop_once_item;
           clear deloop_once);
      try (assert (pf1 : strs' = str0)
            by (clear -pf e; abstract (subst str'; rewrite ?RightId, ?LeftId in pf; exact pf));
           specialize (deloop_once_production str0 valid _ nonterminal pats' p'' pf1 (snd H)));
      try (destruct deloop_once_item as [ret|ret];
           [ | right; repeat first [ subst str' | subst strs' ]; rewrite ?LeftId, ?RightId; assumption ]);
      try (destruct deloop_once_production as [ret'|ret'];
           [ | right; repeat first [ subst str' | subst strs' ]; rewrite ?LeftId, ?RightId; assumption ]).
      { (** empty, empty *)
        left.
        exists (ParseProductionCons (projT1 ret) (projT1 ret')).
        exact (projT2 ret, projT2 ret'). }
      { (** empty, nonempty *)
        left.
        exists (ParseProductionCons p' (projT1 ret')).
        refine (expand_forall_parse_of_item _ (fst H), projT2 ret').
        unfold P in *; simpl.
        clear -e e' pf1 rdata.
        abstract (intros; edestruct lt_dec; deloop_t). }
      { (** nonempty, empty *)
        left.
        exists (ParseProductionCons (projT1 ret) p'').
        refine (projT2 ret, expand_forall_parse_of_production _ _ (snd H)).
        unfold P in *; simpl.
        clear -e e' pf0 rdata.
        abstract (intros; edestruct lt_dec; deloop_t). }
      { (** nonempty, nonempty *)
        left.
        exists (ParseProductionCons p' p'').
        refine (expand_forall_parse_of_item _ (fst H),
                expand_forall_parse_of_production _ _ (snd H));
          unfold P in *; simpl;
          clear -e e' pf rdata;
          abstract (intros; edestruct lt_dec; deloop_t). } }
  Defined.

  Fixpoint deloop_once {str0 valid str nonterminal pats} (p : parse_of String G str pats)
    := @deloop_once' (@deloop_once) (@deloop_once_production) str0 valid str nonterminal pats p
  with deloop_once_production {str0 valid str nonterminal pat} (p : parse_of_production String G str pat)
       := @deloop_once_production' (@deloop_once) (@deloop_once_production) str0 valid str nonterminal pat p.
  Definition deloop_once_item {str0 valid str nonterminal it} (p : parse_of_item String G str it)
    := @deloop_once_item' (@deloop_once) str0 valid str nonterminal it p.

  Definition parse_of__of__parse_of_item_eq' {str0 valid str nonterminal}
             (pf : str = str0 :> String)
             (p : p_parse_nonterminal str0 valid str nonterminal)
  : P str0 valid str nonterminal * p_parse str0 (remove_nonterminal valid nonterminal) str (Lookup G nonterminal).
  Proof.
    refine (match projT1 p as p' in parse_of_item _ _ str' it'
                  return match it' with
                           | Terminal _ => True
                           | NonTerminal nonterminal' => str' = str0 -> Forall_parse_of_item (P str0 valid) p' -> P str0 valid str' nonterminal' * p_parse str0 (remove_nonterminal valid nonterminal') str' (Lookup G nonterminal')
                         end
            with
              | ParseTerminal _ => I
              | ParseNonTerminal nonterminal' _ p'
                => fun pf' H' => (fst H', if @deloop_once str0 valid _ nonterminal' _ p' pf' (snd H') then _ else _)
            end pf (projT2 p));
    assumption.
  Defined.
  Definition parse_of__of__parse_of_item_eq {str0 valid str nonterminal} pf p
    := snd (@parse_of__of__parse_of_item_eq' str0 valid str nonterminal pf p).

  Local Instance methods : @parser_computational_dataT _ String
    := { methods' := methods' }.

  Local Instance prestrdata : @parser_computational_prestrdataT _ String G methods idM
    := { prelower_nonterminal_state str0 valid nonterminal str st := st;
         prelower_string_head str0 valid prod prods str st
         := match st with
              | None => None
              | Some p => match projT1 p as p' in parse_of _ _ str' prods' return Forall_parse_of (P str0 valid) p' -> option (p_parse_production str0 valid str' (hd prod prods')) with
                            | ParseHead _ _ _ p' => fun H => Some (existT _ p' H)
                            | ParseTail _ _ _ _ => fun _ => None
                          end (projT2 p)
            end;
         prelower_string_tail str0 valid prod prods str st
         := match st with
              | None => None
              | Some p => match projT1 p as p' in parse_of _ _ str' prods' return Forall_parse_of (P str0 valid) p' -> option (p_parse str0 valid str' (tl prods')) with
                            | ParseTail _ _ _ p' => fun H => Some (existT _ p' H)
                            | ParseHead _ _ _ _ => fun _ => None
                          end (projT2 p)
            end;
         prelift_lookup_nonterminal_state_lt str0 valid nonterminal str pf := option_map (parse_of__of__parse_of_item_lt pf);
         prelift_lookup_nonterminal_state_eq str0 valid nonterminal str pf := option_map (parse_of__of__parse_of_item_eq pf) }.

  Local Instance strdata : @parser_computational_strdataT _ String G methods
    := prestrdata.

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

    Section parts.
      Section common.
        Section types.
          Context (str0 : String)
                  (valid : nonterminals_listT).

          Let prefix str T := str ≤s str0
                              -> sub_nonterminals_listT valid initial_nonterminals_data
                              -> T.

          Let alt := False.

          Section T_nonterminal.
            Context (nonterminal : string) (str : StringWithSplitState String (split_stateT str0 valid (include_nonterminal _ nonterminal))).
            Let ret := mp_parse_nonterminal str0 valid str nonterminal.

            Definition T_nonterminal_success  : Type
              := ret.

            Definition T_nonterminal_failure : Type
              := match state_val str with
                   | None => ret -> False
                   | Some p => alt
                 end.
          End T_nonterminal.

          Section T_item.
            Context (it : item CharType) (str : StringWithSplitState String (split_stateT str0 valid it)).

            Let ret := mp_parse_item str0 valid str it.

            Definition T_item_success : Type
              := ret.
            Definition T_item_failure : Type
              := match state_val str with
                   | None => ret -> False
                   | Some p => alt
                 end.
          End T_item.

          Section T_production.
            Context (prod : production CharType) (str : StringWithSplitState String (split_stateT str0 valid prod)).

            Let ret := mp_parse_production str0 valid str prod.

            Definition T_production_success : Type
              := ret.
            Definition T_production_failure : Type
              := match state_val str with
                   | None => ret -> False
                   | Some p => alt
                 end.
          End T_production.

          Section T_productions.
            Context (prods : productions CharType) (str : StringWithSplitState String (split_stateT str0 valid prods)).

            Let ret := mp_parse str0 valid str prods.

            Definition T_productions_success : Type
              := ret.

            Definition T_productions_failure : Type
              := match state_val str with
                   | None => ret -> False
                   | Some p => alt
                 end.
          End T_productions.
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

        Hint Constructors minimal_parse_of minimal_parse_of_nonterminal minimal_parse_of_production minimal_parse_of_item unit prod unit : minimal_instance_db.
        Hint Unfold T_item_success T_item_failure T_production_success T_production_failure T_productions_success T_productions_failure T_nonterminal_success T_nonterminal_failure
             DependentlyTyped.T_item_success DependentlyTyped.T_item_failure DependentlyTyped.T_production_success DependentlyTyped.T_production_failure DependentlyTyped.T_productions_success DependentlyTyped.T_productions_failure DependentlyTyped.T_nonterminal_success DependentlyTyped.T_nonterminal_failure
             p_parse_production p_parse p_parse_item p_parse_nonterminal
             mp_parse_production mp_parse mp_parse_item mp_parse_nonterminal : minimal_instance_db.

        Lemma match_hd_helper {x xs}
              {str P}
              (p : parse_of String G str (x::xs))
              (Hp : Forall_parse_of P p)
              R
              k
              P0 P1
        : match match p as p' in (parse_of _ _ str' prods')
                      return
                      (Forall_parse_of P p'
                       -> option (R str' (hd x prods')))
                with
                  | ParseHead str pat pats p' => fun H => Some (k str pat pats p' H)
                  | ParseTail str pat pats p' => fun _ => None
                end Hp
                return Type
          with
            | Some _ => P0
            | None => P1
          end
          -> match p return Type with
               | ParseHead str pat pats p' => P0
               | ParseTail str pat pats p' => P1
             end.
        Proof.
          destruct p; try split; try tauto; try congruence.
        Qed.

        Lemma match_tl_helper {x xs}
              {str P}
              (p : parse_of String G str (x::xs))
              (Hp : Forall_parse_of P p)
              R
              k
              P0 P1
        : match match p as p' in (parse_of _ _ str' prods')
                      return
                      (Forall_parse_of P p'
                       -> option (R str' (tl prods')))
                with
                  | ParseHead str pat pats p' => fun _ => None
                  | ParseTail str pat pats p' => fun H => Some (k str pat pats p' H)
                end Hp
                return Type
          with
            | Some _ => P0
            | None => P1
          end
          -> match p return Type with
               | ParseHead str pat pats p' => P1
               | ParseTail str pat pats p' => P0
             end.
        Proof.
          destruct p; try split; try tauto; try congruence.
        Qed.

        Local Ltac t''0 :=
          first [ progress cbv zeta
                | intro
                | let H := (match goal with
                              | [ H : StringWithSplitState _ _ |- _ ] => constr:H
                              | [ H : ?T |- _ ] => match eval hnf in T with
                                                     | StringWithSplitState _ _
                                                       => constr:H
                                                   end
                            end) in
                  let s := fresh "s" in
                  let st := fresh "st" in
                  destruct H as [s st];
                    change (StringLike.Core.string_val {| string_val := s |}) with s in *;
                    change (StringLike.Core.state_val {| state_val := st |}) with st in *;
                    simpl
                | match goal with
                    | [ H : option _ |- _ ] => destruct H; simpl
                    | [ H : ?T |- _ ] => match eval hnf in T with
                                           | option _ => destruct H; simpl
                                         end
                  end
                | match goal with
                    | [ H : appcontext[StringLike.Core.string_val {| string_val := ?s |}] |- _ ] => change (StringLike.Core.string_val {| string_val := s |}) with s in *
                    | [ H : appcontext[StringLike.Core.state_val {| state_val := ?s |}] |- _ ] => change (StringLike.Core.state_val {| state_val := s |}) with s in *
                  end ].

        Local Ltac t'' :=
          idtac;
          match goal with
            | _ => intro
            | [ H : False |- _ ] => solve [ destruct H ]
            | [ H : match _ with _ => _ end |- _ ] => progress hnf in H
            | _ => solve [ change unit; constructor ]
            | [ a : _, b : Forall_parse_of_production _ _ |- Forall_parse_of_production _ _ ]
              => exact (a, b)
            | [ H : parse_of _ _ _ []  |- _ ] => solve [ exfalso; clear -H; abstract inversion H ]
            | [ H : {| state_val := Some _ |} = {| state_val := None |} |- _ ]
              => solve [ destruct (neq_some_none_state_val H) ]
            | [ H : {| state_val := None |} = {| state_val := Some _ |} |- _ ]
              => solve [ destruct (neq_some_none_state_val (eq_sym H)) ]
            | [ H : _ \/ False |- _ ] => apply or_False in H
            | [ H : _ ≤s _ -> ?B |- _ ] => specialize (H (or_intror eq_refl))
            | [ H : _ ≤s _ -> ?B, H' : _ \/ _ |- _ ]
              => first [ specialize (H (transitivity (str_le1_append _ _ _) H'))
                       | specialize (H (transitivity (str_le2_append _ _ _) H'))
                       | specialize (H (transitivity split_parse_of_production_le1 H'))
                       | specialize (H (transitivity split_parse_of_production_le2 H')) ]
            | [ H : _ ≤s _ -> ?B, H' : _ ≤s _ |- _ ]
              => first [ specialize (H (transitivity (str_le1_append _ _ _) H'))
                       | specialize (H (transitivity (str_le2_append _ _ _) H'))
                       | specialize (H (transitivity split_parse_of_production_le1 H'))
                       | specialize (H (transitivity split_parse_of_production_le2 H')) ]
            | [ H : sub_nonterminals_listT ?x ?y -> _ |- _ ] => specialize (H (reflexivity _))
            | [ H : sub_nonterminals_listT _ _, H' : sub_nonterminals_listT _ _ _ -> _ |- _ ]
              => specialize (fun arg => H' (sub_nonterminals_listT_remove_2 _ arg _ H))
            | [ H : sub_nonterminals_listT _ _, H' : is_valid_nonterminal _ _ = true |- _ ]
              => unique pose proof (H _ H')
            | [ H : context[map _ nil] |- _ ] => progress simpl in H
            | [ H : context[map _ (_::_)] |- _ ] => progress simpl in H
            | [ H : appcontext[split_string_for_production _ _ {| state_val := Some _ |} ] |- _ ] => progress simpl in H
            | _ => progress autounfold with minimal_instance_db in *
            | [ H : ?T |- _ ] => match head T with
                                   | match _ with _ => _ end => progress hnf in H
                                 end
            | [ |- ?T ] => (not constr_eq False T); solve [ eauto with minimal_instance_db ] (* work around bugged tactic universe successor anomaly *)
            | [ x : _ |- @sigT ?A _ ]
              => exists (MinParseNonTerminal x : A)
            | [ |- @sigT ?A _ ]
              => first [ (exists (MinParseTerminal _ _ _ _ _ _ _ _ : A))
                       | (exists (MinParseProductionNil _ _ _ _ _ _ _ : A)) ]
            | [ x : minimal_parse_of_item _ _ _ _ _ _ _ _ _, y : minimal_parse_of_production _ _ _ _ _ _ _ _ _, H : _ \/ _ |- @sigT ?A _ ]
              => exists (MinParseProductionCons H x y : A)
            | [ x : minimal_parse_of_production _ _ _ _ _ _ _ _ _
                |- @sigT ?A _ ]
              => exists (MinParseHead _ x : A); assumption
            | [ x : minimal_parse_of _ _ _ _ _ _ _ _ _
                |- @sigT ?A _ ]
              => exists (MinParseTail _ x : A); assumption
            | [ H : sigT _ |- _ ] => destruct H
            | [ H : sig _ |- _ ] => destruct H
            | [ H : prod _ _ |- _ ] => destruct H
            | [ H : and _ _ |- _ ] => destruct H
            | [ H : (_, _) = (_, _) |- _ ] => apply path_prod' in H
            | [ H : ?T |- _ ] => match eval hnf in T with
                                   | (_ * _)%type => destruct H
                                   | (_ /\ _)%type => destruct H
                                 end
            | _ => progress subst
            | _ => progress simpl
            | [ H : _ = _ |- _ ] => progress simpl in H (* work around [simpl in *] causing ~everything, even [admit], to error with "Anomaly: Cannot take the successor of a non variable universe:
(maybe a bugged tactic).
Please report." *)
            | [ H : _ |- _ ] =>
              match goal with
                | [ H' : _ = H |- _ ] => destruct H'
              end
            | [ H : (_ =s _) = true |- _ ] => apply bool_eq_correct in H
            | [ H : is_true (_ =s _) |- _ ] => apply bool_eq_correct in H
            | [ H : _::_ = nil |- _ ] => solve [ inversion H ]
            | [ H : nil = _::_ |- _ ] => solve [ inversion H ]
            | [ H : _::_ = _::_ |- _ ] => inversion H; clear H
            | [ H : Terminal _ = Terminal _ |- _ ] => inversion H; clear H
            | [ H : NonTerminal _ _ = Terminal _ |- _ ] => solve [ inversion H ]
            | [ H : Terminal _ = NonTerminal _ _ |- _ ] => solve [ inversion H ]
            | [ H : NonTerminal _ _ = NonTerminal _ _ |- _ ] => inversion H; clear H
            | [ H : parse_of_item _ _ ?s ?x |- _ ]
              => atomic s;
                not atomic x;
                generalize dependent H;
                let T := fresh in
                set (T := x);
                  generalize (eq_refl : x = T);
                  clearbody T;
                  intros ? H;
                  destruct H
            | [ H : parse_of_production _ _ ?s ?x |- _ ]
              => atomic s;
                not atomic x;
                generalize dependent H;
                let T := fresh in
                set (T := x);
                  generalize (eq_refl : x = T);
                  clearbody T;
                  intros ? H;
                  destruct H
            | [ H : _ |- _ ]
              => simpl in H;

                match type of H with
                  | match match ?p as p' in (parse_of _ _ str' prods')
                                return (Forall_parse_of ?P p'
                                        -> option (?P' ?str0 ?valid str' _))
                          with _ => _
                          end ?f
                    with
                      | Some _ => False
                      | None => ?T -> False
                    end
                    => first [ apply (@match_tl_helper _ _ _ _ p f (fun str' tlv => P' str0 valid str' tlv)) in H
                             | apply (@match_hd_helper _ _ _ _ p f (fun str' tlv => P' str0 valid str' tlv)) in H ]
                end
            | [ H : ?A -> ?B, H' : ?A |- _ ] => specialize (H H')
            | [ H : ?A -> False |- _ ] => let A' := (eval hnf in A) in progress change (A' -> False) in H
            | _ => progress trivial
            | _ => progress auto with arith
            | _ => t''0
            | [ H : (_ + _)%type |- _ ] => destruct H
            | [ |- (_ * _)%type ] => split
            | [ H : minimal_parse_of_item _ _ _ _ _ _ _ _ ?x |- _ ]
              => not atomic x;
                generalize dependent H;
                let T := fresh in
                set (T := x);
                  generalize (eq_refl : x = T);
                  clearbody T;
                  intros ? H;
                  destruct H
            | [ H : minimal_parse_of _ _ _ _ _ _ _ _ ?x |- _ ]
              => not atomic x;
                generalize dependent H;
                let T := fresh in
                set (T := x);
                  generalize (eq_refl : x = T);
                  clearbody T;
                  intros ? H;
                  destruct H
            | [ H : parse_of _ _ ?s ?x |- _ ]
              => atomic s;
                not atomic x;
                generalize dependent H;
                let T := fresh in
                set (T := x);
                  generalize (eq_refl : x = T);
                  clearbody T;
                  intros ? H;
                  destruct H
            | [ H : appcontext[if lt_dec ?a ?b then _ else _] |- _ ]
              => destruct (lt_dec a b)
          end.

        Local Ltac t' :=
          first [ t''
                | match goal with H : true = false |- _ => exfalso; clear -H; congruence end
                | match goal with H : ?x = false, H' : ?x = true |- _ => exfalso; clear -H H'; abstract congruence end
                | abstract omega
                | match goal with H : (?x =s ?x) = false |- _ => erewrite (proj2 (bool_eq_correct _ _ _)) in H by reflexivity end
                | match goal with H : _ -> False |- False => apply H end;
                  abstract (repeat t'') ].

        Local Ltac t_false :=
          idtac;
          match goal with
            | [ |- False ]
              => abstract (
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
          end.

        Local Ltac t :=
          repeat t''0;
          try solve [ repeat t''; exfalso; t_false ].

        Local Obligation Tactic := idtac.

        Definition H_prod_splitT' str0 valid it its str st
          := split_string_lift_T str0 valid it its {| string_val := str ; state_val := st |} (split_string_for_production str0 valid it its {| string_val := str ; state_val := st |}).

        Lemma H_prod_split_helper str0 valid it its str st
        : @H_prod_splitT' str0 valid it its str (Some st).
        Proof.
          subst_body; simpl in *.
          intros ? H.
          simpl in H.
          destruct_head prod.
          destruct_head sum;
            destruct_head prod;
            unfold T_item_failure, T_production_failure in *;
            simpl in *.
          { repeat t''. }
          { repeat t''. }
          { repeat t''. }
        Defined.

        Local Obligation Tactic := t.

        Global Program Instance minimal_parser_dependent_types_extra_success_data'
        : @parser_dependent_types_extra_success_dataT' _ String G _ _.

        Global Program Instance minimal_parser_dependent_types_extra_failure_data'
               (H_prod_split' : forall str0 valid it its str, @H_prod_splitT' str0 valid it its str None)
        : @parser_dependent_types_extra_failure_dataT' _ String G _ _
          := { H_prod_split str0 valid it its str
               := match str with
                    | {| string_val := str' ; state_val := st' |}
                      => match st' with
                           | None => @H_prod_split' str0 valid it its str'
                           | Some st => @H_prod_split_helper str0 valid it its str' st
                         end
                  end }.

        Global Instance minimal_parser_dependent_types_extra_data split_list_complete
        : @parser_dependent_types_extra_dataT _ String G
          := { extra_failure_data := minimal_parser_dependent_types_extra_failure_data' split_list_complete;
               extra_success_data := minimal_parser_dependent_types_extra_success_data' }.
      End common.
    End parts.

    Definition minimal_parse_nonterminal__of__parse
               (H_prod_split' : forall str0 valid it its str, @H_prod_splitT' str0 valid it its str None)
               (nonterminal : string)
               (s : String)
               (p : parse_of_item String G s (NonTerminal _ nonterminal))
               (H : Forall_parse_of_item
                      (fun _ n => is_valid_nonterminal initial_nonterminals_data n = true)
                      p)
    : minimal_parse_of_nonterminal (String := String) (G := G) s initial_nonterminals_data s nonterminal.
    Proof.
      pose proof (fun H' => @parse_nonterminal _ String G (minimal_parser_dependent_types_extra_data H_prod_split') nonterminal s (Some (existT _ p (expand_forall_parse_of_item H' H)))) as H0.
      simpl in *.
      unfold T_nonterminal_success, T_nonterminal_failure in *.
      simpl in *.
      edestruct H0; unfold P;
        repeat match goal with
                 | _ => assumption
                 | [ H : _ -> _ |- _ ] => specialize (H (reflexivity _))
                 | [ H : False |- _ ] => destruct H
                 | _ => intro
                 | [ |- _ /\ _ ] => split
                 | [ |- appcontext[if lt_dec ?a ?b then _ else _] ]
                   => destruct (lt_dec a b)
               end.
    Defined.
  End minimal.
End recursive_descent_parser.

Print Assumptions minimal_parse_nonterminal__of__parse.
