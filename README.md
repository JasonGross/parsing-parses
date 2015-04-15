Parsing Parses − Proven Correct Dependently Typed Parser
======================================================================

This repository holds the source code of a dependently-typed parser
written in Coq, which proves its own correctness by parsing parse
trees.

## Dependencies:
  * To build the library:          Coq 8.4
  * To step through the examples:  GNU Emacs 23.4.1, Proof General 4.3

## Compiling and running the code
  * To build the library: `make`

Connection with the Parsing Parses paper
----------------------------------------

All file names are relative to src/Parsers/

BooleanRecognizer.v                          - parser returning bools, written before the dependently typed one (section 1.2, section 7.1)
ContextFreeGrammar.v                         - definition of a context free grammar (section 2.1), and of parse trees (section 2.2)
Grammars/ABStar.v                            - definition of the grammar for the regular expression (ab)* (section 2.1.1)
BooleanRecognizer.v                          - soundness and completeness of parser returning bools (section 2.3)
MinimalParse.v                               - definition of "minimal" parse trees (section 4)
DependentlyTyped.v                           - declaration of the interface and implementation of the parser (section 5, figures 1 and 2)
DependentlyTypedMinimalOfParseFactored.v     - instantiation of the parser that parses parse trees and returns minimal parse trees (section 5; the deloop of the 5.1 is [deloop_once] in this file
DependentlyTypedMinimal.v                    - instantiation of parser returning (MinParseTreeOf nt s + (MinParseTreeOf nt s -> False)); a slightly different factoring of the components from what appears in section 5.4
MinimalParseOfParse.v                        - construction of ParseTreeOf from MinParseTreeOf (not needed in paper due to slightly different factoring from what appears in 5.4), also a direct construction of MinParseOf from ParseTreeOf, superseded by the construction of DependentlyTypedMinimalOfParseFactored.v and the paper
DependentlyTypedMinimalOfParseFactoredFull.v - single definition to construct MinParseTreeOf from ParseTreeOf: [minimal_parse_nonterminal__of__parse] corresponds to min_parse of section 5.4
DependentlyTypedSum.v                        - helper for DependentlyTypedMinimalOfParseFactored.v; the extra 300 lines of code mentioned in 7.2