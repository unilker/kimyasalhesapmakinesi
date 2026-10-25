# Independent cross-checks

These scripts verify the app's calculations against independent references.
They run in CI on every push.

| Check | Reference | Command |
|---|---|---|
| All 47 solver equations, every unknown, 40 random inputs each (6 700 cases), including that "no solution" answers really have no valid root | Equations re-written in textbook form in Python | `flutter test tool/crosscheck/dump_solvers_test.dart && python3 tool/crosscheck/check_solvers.py tool/crosscheck/out_solvers.json` |
| Calculator expression parser, 3 000 random expressions | Python `math` | `python3 tool/crosscheck/expressions.py gen tool/crosscheck/out_expr_in.json && flutter test tool/crosscheck/eval_expressions_test.dart && python3 tool/crosscheck/expressions.py check tool/crosscheck/out_expr_out.json` |
| All 119 unit conversion factors | [pint](https://pint.readthedocs.io) | `pip install pint && python3 tool/crosscheck/check_units.py` |

Further reference tests live in `test/core/`:
`atomic_weights_test.dart` (CIAAW 2024), `pubchem_mw_test.dart` (PubChem
molecular weights) and `textbook_equations_test.dart` (38 balanced
reactions with conservation checks).
