# Systemic Risk Components in a Network Model of Contagion — code

Code that reproduces the numerical examples (Section 4.1: Tables 2–5 and the numbers quoted in
Sections 4.1–4.5) of

> Staum, J., Feng, M., & Liu, M. (2016). Systemic risk components in a network model of contagion.
> *IIE Transactions*, 48(6), 501–510. https://doi.org/10.1080/0740817X.2015.1110650

If you use this code, please cite the paper.

## Quick start

```matlab
% MATLAB (tested with R2023b; no toolboxes needed). From this folder:
reproduce_paper
```

This computes both examples, writes Tables 2–5 to `tables/` as CSV files and checks every printed
value against the published article (`verify/verification_report.csv`), all in a few seconds. The
examples are deterministic (no simulation), so the results are exact. One entry of Table 5 differs
from the printed value; see [Difference from the published article](#difference-from-the-published-article).

## The paper in brief

A financial system is a network of n nodes (firms) with interlocking balance sheets: equity γ,
external debt δ, internal liabilities L (L_ij = amount borrowed by node i from node j), cash η and
risky external assets Θ. At time 1 the risky assets are worth Θa; the nodes pay their debts by the
Eisenberg–Noe clearing mechanism, and the **cost** of the system is the external creditors' loss
δ'(1 − f*), where f* are the fractions of their liabilities that the nodes pay. The paper
attributes this cost (systemic risk = expected cost) to the nodes with the Shapley or
Aumann–Shapley value. Each **balance-sheet scheme** specifies the counterfactual system in which
node i participates at level λ_i:

| Method (Table 1) | Value | Participation λ_i scales | Accounting equation enforced by | Code |
|---|---|---|---|---|
| External creditors' loss | — | — | — | `external_creditors_loss.m` |
| External assets (Sec. 4.2) | Shapley, A–S | risky assets | cash replaces risky assets | `allocation_external_assets.m` |
| Transmission / Leverage (Sec. 4.3) | Shapley / A–S | liabilities (borrower) | equity replaces liability, cash replaces internal loans | `allocation_transmission_leverage.m` |
| Intermediation (Sec. 4.4) | Shapley, A–S | size, risky assets, equity; loans √(λ_iλ_j) | external liability replaces internal liability | `allocation_intermediation.m` |
| Solvency (Sec. 4.5) | A–S | as intermediation; loans λ_i (borrower) | as intermediation | `allocation_solvency.m` |
| Absorption (Sec. 4.6) | A–S | as intermediation; loans λ_j (lender) | as intermediation | `allocation_absorption.m` |
| Funding (Sec. 4.7) | A–S | equity, external debt, risky assets; loans λ_j | borrowing provides cash | `allocation_funding.m` |

The Shapley value (Eq. 2) is computed exactly from the costs of all 2^n subsets of nodes. The
Aumann–Shapley value (Eq. 1) is computed in closed form for the homogeneous schemes (solvency,
absorption, funding; Online Supplement C.3–C.5) and by integrating the piecewise-constant gradient
between breakpoints for the external-assets and leverage schemes (Online Supplement C.1–C.2).

## Difference from the published article

**Table 5, external assets, Aumann–Shapley value, node 5: the article prints 50,669; this code
gives 50,667.** All other values of Tables 2–5 and of the text are reproduced as printed.

The external-assets Aumann–Shapley value integrates the marginal prices of wealth ζ(t1) over
t ∈ [0, 1]; ζ is constant between breakpoints, the values of t at which a node of the
counterfactual system t1 becomes borderline. The procedure of Online Supplement C.1 predicts the
next breakpoint from one-sided derivatives chosen by the sign of each node's profit. When a
borderline node changes colour because of the other nodes' income, this choice can be wrong: the
procedure then predicts a value of t at which no node is borderline and skips the true breakpoint.
In Example 2 this happens at t = 0.937942: the predicted next breakpoint is 0.927236, the true one
0.927267, and ζ is integrated with the wrong value on that short interval. The original code
implemented this procedure and produced the printed row 45,404 / 0 / 41,899 / 0 / 50,669 / −3,400,
which sums to 134,573.38 instead of the system cost 134,571.07 (an Aumann–Shapley value must add up
to the cost). This code checks each predicted interval: if the node colours just below the current
breakpoint and just above the predicted one differ, a breakpoint was skipped and it is located by
bisection. The corrected row, 45,404.48 / 0 / 41,899.19 / 0 / 50,667.05 / −3,399.64, sums to the
system cost; at the printed precision only node 5 changes. Independent checks (integration of ζ
on a fine grid; bisection on all colour changes) give the same values.

In Example 1 and in all other methods the original procedure is exact. Among 300 random networks
of 2–5 nodes (`tests/`), the original external-assets search skipped a breakpoint in 13.

## Paper result → code

| Result | Produced by | Output |
|---|---|---|
| Table 2 (scenarios of Example 1, nodes' losses 1 − f*) | `scripts/example1_two_node.m` | `tables/Table2_Example1_Scenarios.csv` |
| Table 3 (systemic risk components, Example 1) | `scripts/example1_two_node.m` | `tables/Table3_Example1_Components.csv` |
| Stand-alone risks and interactions quoted in Sections 4.2–4.4 | `scripts/example1_two_node.m` | `tables/Text_Example1_StandAloneRisks.csv` |
| Table 4 (balance sheets, f*, sensitivities ζ, Example 2) | `scripts/example2_six_node.m` | `tables/Table4_Example2_BalanceSheets.csv` |
| Table 5 (cost allocations, Example 2; one corrected entry) and the system cost 134,571 | `scripts/example2_six_node.m` | `tables/Table5_Example2_Allocations.csv` |
| Figures 1 and 2 (network diagrams) | not computed; the inputs are entered in the two scripts | — |

Amounts are in thousands in the networks (Figures 1–2, Table 4) and in units in Tables 3 and 5,
as in the paper.

## Folder structure

```
reproduce_paper.m                 entry point: Tables 2-5, text values, verification
functions/
  make_network.m                  time-0 balance sheets (Eq. 3), Assumption 1 checks
  clearing_payments.m             clearing payments (Prop. 1), node colours, derivatives
                                  (Cor. 1), marginal prices of wealth zeta (Eq. 10, 13)
  external_creditors_loss.m       cost of a system (Eq. 7)
  all_subsets.m, shapley_value.m  Shapley value from the costs of all subsets (Eq. 2)
  allocation_*.m                  one file per balance-sheet scheme (Sections 4.2-4.7)
  all_allocations.m               all ten methods, in the row order of Tables 3 and 5
scripts/
  example1_two_node.m             Example 1: Figure 1, Table 2 -> Tables 2, 3, text values
  example2_six_node.m             Example 2: Figure 2, Table 4 -> Tables 4, 5
tables/                           CSV output (full precision)
verify/
  verify_against_paper.m          printed values of the article and the comparison
  verification_report.csv         one row per printed value (166 values)
tests/
  run_tests.m                     regression tests (snapshot + original code)
  make_reference_outputs.m        writes the snapshot tests/reference_outputs.mat
  test_efficiency.m               allocations add up to the cost of the system
  test_against_original.m         agreement with original_2014/
  reference_outputs.m, random_networks.m, example_cases_for_tests.m
original_2014/                    the authors' original code that produced the published
                                  tables (reference for the tests; not maintained)
```

## Notation: code → paper

| Code | Paper | Meaning |
|---|---|---|
| `Network.Liabilities` | L | L(i,j) = amount borrowed by node i from node j |
| `Network.ExternalDebt` | δ | external debt |
| `Network.Cash` | η | cash |
| `Network.RiskyAssets` | Θ1 | time-0 value of each node's risky assets |
| `RiskyProfit` | Θ(a − 1) | profit on the risky assets in a scenario |
| `Network.Size`, `Network.Equity` | ς, γ | balance-sheet size and equity (from Eq. 3) |
| `Clearing.Income` | e | time-1 value of external assets, η + Θa |
| `Clearing.TotalDebt` | p̄ | δ + L1 |
| `Clearing.Pi`, `Clearing.Pi0` | Π, Π⁰ | outflow fractions to nodes and to external creditors |
| `Clearing.Payments`, `.PayFraction`, `.Equity` | p*, f*, v* | clearing payments, payment fractions, time-1 equity |
| `Clearing.Red`, `.Green`, `.Borderline` | R, G | node colours (Section 3.2) |
| `Clearing.LeftDeriv`, `.RightDeriv` | ∇⁻ₑp*, ∇⁺ₑp* | one-sided derivatives (Cor. 1) |
| `Clearing.Zeta` | ζ | marginal prices of wealth |
| `Lambda`, `Scale` | λ, t | participation vector, scale on the diagonal t1 |
| `Breakpoints`, `Widths`, `Midpoints` | t̃ᵢ, ωᵢ, μᵢ | A–S integration intervals |

## Verification

`verify_against_paper.m` holds the values printed in the published article (Tables 2–5 and the
numbers quoted in Sections 4.1–4.5, 166 values) as text, so that the printed precision is known.
Each reproduced value must round to the printed value (|reproduced − printed| ≤ half a unit in the
last printed digit). 165 of the 166 values are reproduced as printed; the Table 5 entry above is
checked against its corrected value (status `corrected (see README)` in the report). The check is
the last step of `reproduce_paper.m`.

`tests/run_tests.m` runs three tests:
- `test_efficiency.m`: for both examples and 300 random networks, the allocations of every method
  add up to the cost of the system (largest gap 8e-13 relative to the balance sheets);
- `test_against_original.m`: all ten methods, clearing payments and ζ agree with the original 2014
  code to 1e-15 (relative) on the same networks, except the external-assets Aumann–Shapley value
  where the original search skipped a breakpoint (13 networks); there the test requires that the
  original allocations do not add up to the cost and the new ones do;
- a comparison with a saved snapshot of all outputs (`tests/reference_outputs.mat`).

## Numerical details

- Node colours are decided with an absolute tolerance of 1e-8 on 1 − f* and on v* (as in the
  original code); the amounts of the examples are in thousands.
- Counterfactual systems with λ_i = 0 have nodes without debt (p̄_i = 0); for them Π_i· = 0,
  Π⁰_i = 0 and f*_i = 1, as in Section 3.1.
- The breakpoint searches follow Online Supplement C.1 (external assets) and C.2 (leverage). For
  external assets, each predicted interval is checked by comparing the node colours at points
  1e-6 of the interval's width inside its ends, and a skipped breakpoint is located by bisection
  to 1e-14; there colours are decided with a relative tolerance of 1e-12.

## Provenance

The original code (`original_2014/`, MATLAB, 2014) was written for the paper; the scripts
`RunTwoNodeNetwork.m`, `SimTwoNodeNetwork.m` and `SimSixNodeNetwork.m` produced Tables 3 and 5. It
built on an earlier implementation for the working paper Liu and Staum (2012, SSRN 1726107), which
is not included. The restructured code computes the same quantities with the same algorithms,
except for the corrected breakpoint search described above.

## Run time

About 4 seconds for `reproduce_paper` (Intel Core i7-1280P, MATLAB R2023b), about 1 minute for
`tests/run_tests`.

## Change log

- **2026-11 (v1.0.0)**: archived version. Restructured the 2014 code: one entry point, one file
  per balance-sheet scheme, paper notation, no global state, CSV output and verification against
  the published article, regression tests. Corrected the breakpoint search of the external-assets
  Aumann–Shapley value (see [Difference from the published article](#difference-from-the-published-article)). Example 1 is now entered as in Figure 1 and Table 2
  (three external assets and their returns a) instead of one portfolio return per node; in
  scenario 2 the original script used a 0% return for node 2's portfolio, Table 2 implies 5%. All
  published values are the same with both, because node 2 does not default in that scenario.
- **2014**: original code (`original_2014/`).

## License

MIT (see `LICENSE`).
