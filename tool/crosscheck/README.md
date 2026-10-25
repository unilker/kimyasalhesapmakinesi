# Independent cross-checks

These scripts verify the app's calculations against independent references.
They run in CI on every push.

| Check | Reference | Command |
|---|---|---|
| All solver equations, every unknown, 40 random inputs each (8 700+ cases), including that "no solution" answers really have no valid root | Equations re-written in textbook form in Python | `flutter test tool/crosscheck/dump_solvers_test.dart && python3 tool/crosscheck/check_solvers.py tool/crosscheck/out_solvers.json` |
| Calculator expression parser, 3 000 random expressions | Python `math` | `python3 tool/crosscheck/expressions.py gen tool/crosscheck/out_expr_in.json && flutter test tool/crosscheck/eval_expressions_test.dart && python3 tool/crosscheck/expressions.py check tool/crosscheck/out_expr_out.json` |
| All unit conversion factors | [pint](https://pint.readthedocs.io) | `pip install pint && python3 tool/crosscheck/check_units.py` |
| Student t quantiles (1 200), Grubbs critical values (294), 300 random regressions and summaries | scipy / numpy | `flutter test tool/crosscheck/dump_stats_test.dart && python3 tool/crosscheck/check_stats.py tool/crosscheck/out_stats.json` |
| 400 random titrations (strong/weak, polyprotic acids, bases, salts) | Charge balance solved independently with `scipy.optimize.brentq` | `flutter test tool/crosscheck/dump_titration_test.dart && python3 tool/crosscheck/check_titration.py tool/crosscheck/out_titration.json` |
| 1 000 random equilibria (ICE tables, K from 1e-30 to 1e30, solids/liquids, every concentration to 1e-9 relative) | Q(x) = K solved by 300-digit [mpmath](https://mpmath.org) bisection | `pip install mpmath && flutter test tool/crosscheck/dump_ice_test.dart && python3 tool/crosscheck/check_ice.py tool/crosscheck/out_ice.json` |

Thermodynamic data: `tool/data/codata_key_values.tsv` (CODATA key values) and
`tool/data/thermo_supplementary.tsv` (CRC/NBS/JANAF; each row passed a
ΔfG = ΔfH − TΔfS consistency check and agrees with a second source and with
the NIST WebBook where it lists the substance). `lib/core/thermo_data.dart`
is generated from them by `tool/gen_thermo.py`; CI fails if it is out of date.

Further reference tests live in `test/core/`:
`atomic_weights_test.dart` (CIAAW 2024), `pubchem_mw_test.dart` (PubChem
molecular weights) and `textbook_equations_test.dart` (38 balanced
reactions with conservation checks).
