# Generates lib/core/chem/elements_data.dart
# Usage: python3 tool/gen_elements.py lib/core/chem/elements_data.dart
import sys
rows = """1|H|Hydrogen|Hidrojen|1.008|0|nonmetal|2.20|g
2|He|Helium|Helyum|4.002602|0|nobleGas||g
3|Li|Lithium|Lityum|6.94|0|alkaliMetal|0.98|s
4|Be|Beryllium|Berilyum|9.0121831|0|alkalineEarthMetal|1.57|s
5|B|Boron|Bor|10.81|0|metalloid|2.04|s
6|C|Carbon|Karbon|12.011|0|nonmetal|2.55|s
7|N|Nitrogen|Azot|14.007|0|nonmetal|3.04|g
8|O|Oxygen|Oksijen|15.999|0|nonmetal|3.44|g
9|F|Fluorine|Flor|18.998403162|0|halogen|3.98|g
10|Ne|Neon|Neon|20.1797|0|nobleGas||g
11|Na|Sodium|Sodyum|22.98976928|0|alkaliMetal|0.93|s
12|Mg|Magnesium|Magnezyum|24.305|0|alkalineEarthMetal|1.31|s
13|Al|Aluminium|Alüminyum|26.9815384|0|postTransitionMetal|1.61|s
14|Si|Silicon|Silisyum|28.085|0|metalloid|1.90|s
15|P|Phosphorus|Fosfor|30.973761998|0|nonmetal|2.19|s
16|S|Sulfur|Kükürt|32.06|0|nonmetal|2.58|s
17|Cl|Chlorine|Klor|35.45|0|halogen|3.16|g
18|Ar|Argon|Argon|39.95|0|nobleGas||g
19|K|Potassium|Potasyum|39.0983|0|alkaliMetal|0.82|s
20|Ca|Calcium|Kalsiyum|40.078|0|alkalineEarthMetal|1.00|s
21|Sc|Scandium|Skandiyum|44.955907|0|transitionMetal|1.36|s
22|Ti|Titanium|Titanyum|47.867|0|transitionMetal|1.54|s
23|V|Vanadium|Vanadyum|50.9415|0|transitionMetal|1.63|s
24|Cr|Chromium|Krom|51.9961|0|transitionMetal|1.66|s
25|Mn|Manganese|Mangan|54.938043|0|transitionMetal|1.55|s
26|Fe|Iron|Demir|55.845|0|transitionMetal|1.83|s
27|Co|Cobalt|Kobalt|58.933194|0|transitionMetal|1.88|s
28|Ni|Nickel|Nikel|58.6934|0|transitionMetal|1.91|s
29|Cu|Copper|Bakır|63.546|0|transitionMetal|1.90|s
30|Zn|Zinc|Çinko|65.38|0|transitionMetal|1.65|s
31|Ga|Gallium|Galyum|69.723|0|postTransitionMetal|1.81|s
32|Ge|Germanium|Germanyum|72.630|0|metalloid|2.01|s
33|As|Arsenic|Arsenik|74.921595|0|metalloid|2.18|s
34|Se|Selenium|Selenyum|78.971|0|nonmetal|2.55|s
35|Br|Bromine|Brom|79.904|0|halogen|2.96|l
36|Kr|Krypton|Kripton|83.798|0|nobleGas|3.00|g
37|Rb|Rubidium|Rubidyum|85.4678|0|alkaliMetal|0.82|s
38|Sr|Strontium|Stronsiyum|87.62|0|alkalineEarthMetal|0.95|s
39|Y|Yttrium|İtriyum|88.905838|0|transitionMetal|1.22|s
40|Zr|Zirconium|Zirkonyum|91.222|0|transitionMetal|1.33|s
41|Nb|Niobium|Niyobyum|92.90637|0|transitionMetal|1.6|s
42|Mo|Molybdenum|Molibden|95.95|0|transitionMetal|2.16|s
43|Tc|Technetium|Teknesyum|97|1|transitionMetal|1.9|s
44|Ru|Ruthenium|Rutenyum|101.07|0|transitionMetal|2.2|s
45|Rh|Rhodium|Rodyum|102.90549|0|transitionMetal|2.28|s
46|Pd|Palladium|Paladyum|106.42|0|transitionMetal|2.20|s
47|Ag|Silver|Gümüş|107.8682|0|transitionMetal|1.93|s
48|Cd|Cadmium|Kadmiyum|112.414|0|transitionMetal|1.69|s
49|In|Indium|İndiyum|114.818|0|postTransitionMetal|1.78|s
50|Sn|Tin|Kalay|118.710|0|postTransitionMetal|1.96|s
51|Sb|Antimony|Antimon|121.760|0|metalloid|2.05|s
52|Te|Tellurium|Tellür|127.60|0|metalloid|2.1|s
53|I|Iodine|İyot|126.90447|0|halogen|2.66|s
54|Xe|Xenon|Ksenon|131.293|0|nobleGas|2.6|g
55|Cs|Caesium|Sezyum|132.90545196|0|alkaliMetal|0.79|s
56|Ba|Barium|Baryum|137.327|0|alkalineEarthMetal|0.89|s
57|La|Lanthanum|Lantan|138.90547|0|lanthanide|1.10|s
58|Ce|Cerium|Seryum|140.116|0|lanthanide|1.12|s
59|Pr|Praseodymium|Praseodim|140.90766|0|lanthanide|1.13|s
60|Nd|Neodymium|Neodim|144.242|0|lanthanide|1.14|s
61|Pm|Promethium|Prometyum|145|1|lanthanide|1.13|s
62|Sm|Samarium|Samaryum|150.36|0|lanthanide|1.17|s
63|Eu|Europium|Evropiyum|151.964|0|lanthanide|1.2|s
64|Gd|Gadolinium|Gadolinyum|157.249|0|lanthanide|1.20|s
65|Tb|Terbium|Terbiyum|158.925354|0|lanthanide|1.1|s
66|Dy|Dysprosium|Disprosyum|162.500|0|lanthanide|1.22|s
67|Ho|Holmium|Holmiyum|164.930329|0|lanthanide|1.23|s
68|Er|Erbium|Erbiyum|167.259|0|lanthanide|1.24|s
69|Tm|Thulium|Tulyum|168.934219|0|lanthanide|1.25|s
70|Yb|Ytterbium|İterbiyum|173.045|0|lanthanide|1.1|s
71|Lu|Lutetium|Lutesyum|174.96669|0|lanthanide|1.27|s
72|Hf|Hafnium|Hafniyum|178.486|0|transitionMetal|1.3|s
73|Ta|Tantalum|Tantal|180.94788|0|transitionMetal|1.5|s
74|W|Tungsten|Tungsten|183.84|0|transitionMetal|2.36|s
75|Re|Rhenium|Renyum|186.207|0|transitionMetal|1.9|s
76|Os|Osmium|Osmiyum|190.23|0|transitionMetal|2.2|s
77|Ir|Iridium|İridyum|192.217|0|transitionMetal|2.20|s
78|Pt|Platinum|Platin|195.084|0|transitionMetal|2.28|s
79|Au|Gold|Altın|196.966570|0|transitionMetal|2.54|s
80|Hg|Mercury|Cıva|200.592|0|transitionMetal|2.00|l
81|Tl|Thallium|Talyum|204.38|0|postTransitionMetal|1.62|s
82|Pb|Lead|Kurşun|207.2|0|postTransitionMetal|2.33|s
83|Bi|Bismuth|Bizmut|208.98040|0|postTransitionMetal|2.02|s
84|Po|Polonium|Polonyum|209|1|postTransitionMetal|2.0|s
85|At|Astatine|Astatin|210|1|halogen|2.2|s
86|Rn|Radon|Radon|222|1|nobleGas|2.2|g
87|Fr|Francium|Fransiyum|223|1|alkaliMetal|0.7|s
88|Ra|Radium|Radyum|226|1|alkalineEarthMetal|0.9|s
89|Ac|Actinium|Aktinyum|227|1|actinide|1.1|s
90|Th|Thorium|Toryum|232.0377|0|actinide|1.3|s
91|Pa|Protactinium|Protaktinyum|231.03588|0|actinide|1.5|s
92|U|Uranium|Uranyum|238.02891|0|actinide|1.38|s
93|Np|Neptunium|Neptünyum|237|1|actinide|1.36|s
94|Pu|Plutonium|Plütonyum|244|1|actinide|1.28|s
95|Am|Americium|Amerikyum|243|1|actinide|1.3|s
96|Cm|Curium|Küriyum|247|1|actinide|1.3|s
97|Bk|Berkelium|Berkelyum|247|1|actinide|1.3|s
98|Cf|Californium|Kaliforniyum|251|1|actinide|1.3|s
99|Es|Einsteinium|Aynştaynyum|252|1|actinide|1.3|s
100|Fm|Fermium|Fermiyum|257|1|actinide|1.3|s
101|Md|Mendelevium|Mendelevyum|258|1|actinide|1.3|s
102|No|Nobelium|Nobelyum|259|1|actinide|1.3|s
103|Lr|Lawrencium|Lavrensiyum|266|1|actinide|1.3|s
104|Rf|Rutherfordium|Rutherfordiyum|267|1|transitionMetal||u
105|Db|Dubnium|Dubniyum|268|1|transitionMetal||u
106|Sg|Seaborgium|Seaborgiyum|269|1|transitionMetal||u
107|Bh|Bohrium|Bohriyum|270|1|transitionMetal||u
108|Hs|Hassium|Hassiyum|269|1|transitionMetal||u
109|Mt|Meitnerium|Meitneriyum|278|1|unknown||u
110|Ds|Darmstadtium|Darmstadtiyum|281|1|unknown||u
111|Rg|Roentgenium|Röntgenyum|282|1|unknown||u
112|Cn|Copernicium|Kopernikyum|285|1|unknown||u
113|Nh|Nihonium|Nihonyum|286|1|unknown||u
114|Fl|Flerovium|Flerovyum|289|1|unknown||u
115|Mc|Moscovium|Moskovyum|290|1|unknown||u
116|Lv|Livermorium|Livermoryum|293|1|unknown||u
117|Ts|Tennessine|Tennesin|294|1|unknown||u
118|Og|Oganesson|Oganesson|294|1|unknown||u""".strip().split("\n")

L = 'spdf'
order = []
for s in range(1, 9):
    for l in range(min(s, 4) - 1, -1, -1):
        n = s - l
        if n > l:
            order.append((n, l))
order.sort(key=lambda x: (x[0] + x[1], x[0]))

exceptions = {
    24: {(3,2):5,(4,0):1}, 29: {(3,2):10,(4,0):1},
    41: {(4,2):4,(5,0):1}, 42: {(4,2):5,(5,0):1}, 44: {(4,2):7,(5,0):1},
    45: {(4,2):8,(5,0):1}, 46: {(4,2):10,(5,0):0}, 47: {(4,2):10,(5,0):1},
    57: {(4,3):0,(5,2):1}, 58: {(4,3):1,(5,2):1}, 64: {(4,3):7,(5,2):1},
    78: {(5,2):9,(6,0):1}, 79: {(5,2):10,(6,0):1},
    89: {(5,3):0,(6,2):1}, 90: {(5,3):0,(6,2):2}, 91: {(5,3):2,(6,2):1},
    92: {(5,3):3,(6,2):1}, 93: {(5,3):4,(6,2):1}, 96: {(5,3):7,(6,2):1},
    103: {(6,2):0,(7,1):1},
}
noble = [(2,'He'),(10,'Ne'),(18,'Ar'),(36,'Kr'),(54,'Xe'),(86,'Rn')]

def config(z):
    occ = {}
    left = z
    for (n,l) in order:
        if left <= 0: break
        cap = 2*(2*l+1)
        k = min(cap, left)
        occ[(n,l)] = k
        left -= k
    for k,v in exceptions.get(z, {}).items():
        occ[k] = v
    assert sum(occ.values()) == z, z
    return occ

def shorthand(z):
    occ = config(z)
    core = None
    for nz, sym in noble:
        if nz < z: core = (nz, sym)
    if core:
        cocc = config(core[0])
        rest = {k: v - cocc.get(k, 0) for k, v in occ.items() if v - cocc.get(k, 0) > 0}
    else:
        rest = {k: v for k, v in occ.items() if v > 0}
    parts = ['%d%s%d' % (n, L[l], v) for (n, l), v in sorted(rest.items())]
    return ((('[%s] ' % core[1]) if core else '') + ' '.join(parts)).strip()

def period(z):
    for p, lim in enumerate([2,10,18,36,54,86,118], 1):
        if z <= lim: return p
def group(z):
    p = period(z)
    if z == 1: return 1
    if z == 2: return 18
    if p in (2,3):
        start = 3 if p == 2 else 11
        i = z - start
        return 1 + i if i < 2 else 11 + i
    start = {4:19,5:37,6:55,7:87}[p]
    i = z - start
    if p in (6,7):
        if 2 <= i <= 16: return 0  # f-block (La..Lu / Ac..Lr) placed in separate rows
        if i > 16: i -= 14
    return i + 1

out = []
out.append("// GENERATED FILE – element data table.")
out.append("// Atomic masses: IUPAC standard atomic weights (bracketed = mass number of")
out.append("// the longest-lived isotope). Electronegativity: Pauling scale.")
out.append("")
out.append("part of 'element.dart';")
out.append("")
out.append("const List<ChemElement> _elementData = [")
for r in rows:
    z, sym, en, tr, mass, rad, cat, eneg, st = r.split('|')
    z = int(z)
    g = group(z)
    p = period(z)
    eneg_s = eneg if eneg else 'null'
    state = {'s':'solid','l':'liquid','g':'gas','u':'unknown'}[st]
    ms = mass if '.' in mass else mass + '.0'
    out.append("  ChemElement(%d, '%s', '%s', '%s', %s, %s, ElementCategory.%s, %s, '%s', MatterState.%s, %s, %d)," % (
        z, sym, en, tr, ms, 'true' if rad == '1' else 'false', cat, eneg_s, shorthand(z), state, str(g) if g else 'null', p))
out.append("];")
open(sys.argv[1], 'w').write("\n".join(out) + "\n")
for z in [1,6,24,26,29,46,57,58,64,71,78,79,80,82,90,92,103,104,111,118]:
    print(z, shorthand(z), group(z), period(z))
