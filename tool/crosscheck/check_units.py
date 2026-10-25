"""Checks every unit factor in lib/core/units.dart against the pint library.

  pip install pint && python3 tool/crosscheck/check_units.py
"""
import re
import sys

import pint

ureg = pint.UnitRegistry()
Q = ureg.Quantity

# base unit of each Quantity in units.dart
BASE = {
    'mass': 'g', 'volume': 'L', 'amount': 'mol', 'pressure': 'Pa', 'temperature': 'K',
    'temperatureDifference': 'delta_degC', 'energy': 'J', 'length': 'm', 'time': 's',
    'concentration': 'mol/L', 'density': 'g/mL', 'molarMass': 'g/mol', 'molarEnergy': 'J/mol',
    'molarEntropy': 'J/(mol*K)', 'specificHeat': 'J/(g*K)', 'current': 'A', 'charge': 'C',
    'voltage': 'V', 'rateConstant': '1/s', 'zeroOrderRate': 'mol/L/s',
    'secondOrderRate': 'L/mol/s', 'frequency': 'Hz', 'molality': 'mol/kg',
    'absorptivity': 'L/(mol*cm)', 'cryoscopic': 'K*kg/mol',
}
# app unit id -> pint expression
PINT = {
    'mass': {'g': 'g', 'kg': 'kg', 'mg': 'mg', 'ug': 'ug', 'ng': 'ng', 't': 'metric_ton', 'lb': 'lb', 'oz': 'oz'},
    'volume': {'L': 'L', 'mL': 'mL', 'uL': 'uL', 'dL': 'dL', 'm3': 'm**3', 'cm3': 'cm**3', 'dm3': 'dm**3', 'gal': 'gallon'},
    'amount': {'mol': 'mol', 'mmol': 'mmol', 'umol': 'umol', 'nmol': 'nmol', 'kmol': 'kmol'},
    'pressure': {'atm': 'atm', 'Pa': 'Pa', 'kPa': 'kPa', 'MPa': 'MPa', 'bar': 'bar', 'mbar': 'mbar',
                 'mmHg': 'mmHg', 'Torr': 'torr', 'psi': 'psi'},
    'energy': {'J': 'J', 'kJ': 'kJ', 'MJ': 'MJ', 'cal': 'cal', 'kcal': 'kcal', 'eV': 'eV', 'Wh': 'Wh',
               'kWh': 'kWh', 'Latm': 'L*atm'},
    'length': {'m': 'm', 'km': 'km', 'cm': 'cm', 'mm': 'mm', 'um': 'um', 'nm': 'nm', 'A': 'angstrom',
               'pm': 'pm', 'in': 'inch', 'ft': 'foot'},
    'time': {'s': 's', 'ms': 'ms', 'min': 'min', 'h': 'h', 'd': 'day', 'y': 'julian_year'},
    'concentration': {'M': 'mol/L', 'mM': 'mmol/L', 'uM': 'umol/L', 'nM': 'nmol/L', 'molm3': 'mol/m**3'},
    'density': {'gmL': 'g/mL', 'gcm3': 'g/cm**3', 'kgL': 'kg/L', 'gL': 'g/L', 'kgm3': 'kg/m**3'},
    'molarMass': {'gmol': 'g/mol', 'kgmol': 'kg/mol'},
    'molarEnergy': {'kJmol': 'kJ/mol', 'Jmol': 'J/mol', 'kcalmol': 'kcal/mol', 'calmol': 'cal/mol',
                    'eV': 'eV*N_A'},
    'molarEntropy': {'JmolK': 'J/(mol*K)', 'kJmolK': 'kJ/(mol*K)', 'calmolK': 'cal/(mol*K)'},
    'specificHeat': {'JgK': 'J/(g*K)', 'JkgK': 'J/(kg*K)', 'calgK': 'cal/(g*K)'},
    'current': {'A': 'A', 'mA': 'mA'},
    'charge': {'C': 'C', 'mAh': 'mA*h', 'Ah': 'A*h'},
    'voltage': {'V': 'V', 'mV': 'mV'},
    'rateConstant': {'s-1': '1/s', 'min-1': '1/min', 'h-1': '1/h', 'd-1': '1/day'},
    'zeroOrderRate': {'Ms': 'mol/L/s', 'Mmin': 'mol/L/min', 'Mh': 'mol/L/h'},
    'secondOrderRate': {'M-1s-1': 'L/mol/s', 'M-1min-1': 'L/mol/min', 'M-1h-1': 'L/mol/h'},
    'frequency': {'Hz': 'Hz', 'kHz': 'kHz', 'MHz': 'MHz', 'GHz': 'GHz', 'THz': 'THz'},
    'molality': {'molkg': 'mol/kg', 'mmolkg': 'mmol/kg'},
    'absorptivity': {'Lmolcm': 'L/(mol*cm)'},
    'cryoscopic': {'Kkgmol': 'K*kg/mol'},
    'temperatureDifference': {'K': 'delta_degC', 'C': 'delta_degC', 'F': 'delta_degF'},
}


def main():
    src = open('lib/core/units.dart').read()
    body = src[src.index('const Map<Quantity, List<Unit>> units'):]
    bad = 0
    n = 0
    for block in re.finditer(r'Quantity\.(\w+): \[(.*?)\]', body, re.S):
        q, items = block.group(1), block.group(2)
        for m in re.finditer(r"Unit\('([^']+)', '[^']*', ([^,)]+)(?:, ([^)]+))?\)", items):
            uid, factor, offset = m.group(1), eval(m.group(2)), m.group(3)
            if q in ('percent', 'dimensionless'):
                continue
            if q == 'temperature':
                for v in (-40.0, 0.0, 25.0, 100.0):
                    unit = {'K': 'kelvin', 'C': 'degC', 'F': 'degF'}[uid]
                    want = Q(v, unit).to('kelvin').magnitude
                    got = v * factor + (eval(offset) if offset else 0)
                    n += 1
                    if abs(got - want) > 1e-9:
                        bad += 1
                        print('TEMP', uid, v, got, want)
                continue
            want = Q(1, PINT[q][uid]).to(BASE[q]).magnitude
            n += 1
            if abs(factor - want) > 1e-9 * abs(want):
                bad += 1
                print('MISMATCH %s/%s: app %r, pint %r' % (q, uid, factor, want))
    print('checked', n, 'unit factors; mismatches', bad)
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main())
