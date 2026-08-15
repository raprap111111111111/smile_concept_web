// Domain Value Objects for Consent Form

enum SignerRole { self, guardian, staff }
enum PatientRelation { self, minorDependent }

// ─── Consent Clauses ────────────────────────────────────────────────────────
const List<Map<String, String>> kConsentClauses = [
  {'key': 'treatment_to_be_done',  'title': 'Treatment to be Done'},
  {'key': 'drugs_medications',     'title': 'Drugs & Medications'},
  {'key': 'changes_treatment_plan','title': 'Changes in Treatment Plan'},
  {'key': 'radiograph',            'title': 'Radiograph'},
  {'key': 'removal_of_teeth',      'title': 'Removal of Teeth'},
  {'key': 'crowns_bridges',        'title': 'Crowns (Caps) & Bridges'},
  {'key': 'endodontics',           'title': 'Endodontics (Root Canal)'},
  {'key': 'periodontal_disease',   'title': 'Periodontal Disease'},
  {'key': 'fillings',              'title': 'Fillings'},
  {'key': 'dentures',              'title': 'Dentures'},
];

// ─── Medical Conditions ─────────────────────────────────────────────────────
const List<Map<String, String>> kMedicalConditions = [
  {'key': 'high_bp',           'label': 'High Blood Pressure'},
  {'key': 'low_bp',            'label': 'Low Blood Pressure'},
  {'key': 'epilepsy',          'label': 'Epilepsy / Convulsions'},
  {'key': 'aids_hiv',          'label': 'AIDS or HIV Infection'},
  {'key': 'std',               'label': 'Sexually Transmitted disease'},
  {'key': 'ulcers',            'label': 'Stomach Troubles / Ulcers'},
  {'key': 'fainting',          'label': 'Fainting Seizure'},
  {'key': 'weight_loss',       'label': 'Rapid Weight Loss'},
  {'key': 'radiation',         'label': 'Radiation Therapy'},
  {'key': 'joint_replacement', 'label': 'Joint Replacement / Implant'},
  {'key': 'heart_surgery',     'label': 'Heart Surgery'},
  {'key': 'heart_attack',      'label': 'Heart Attack'},
  {'key': 'thyroid',           'label': 'Thyroid Problem'},
  {'key': 'heart_disease',     'label': 'Heart Disease'},
  {'key': 'heart_murmur',      'label': 'Heart Murmur'},
  {'key': 'hepatitis_liver',   'label': 'Hepatitis / Liver Disease'},
  {'key': 'rheumatic_fever',   'label': 'Rheumatic Fever'},
  {'key': 'hay_fever',         'label': 'Hay Fever / Allergies'},
  {'key': 'respiratory',       'label': 'Respiratory Problems'},
  {'key': 'jaundice',          'label': 'Hepatitis / Jaundice'},
  {'key': 'tuberculosis',      'label': 'Tuberculosis'},
  {'key': 'swollen_ankles',    'label': 'Swollen ankles'},
  {'key': 'kidney',            'label': 'Kidney disease'},
  {'key': 'diabetes',          'label': 'Diabetes'},
  {'key': 'chest_pain',        'label': 'Chest pain'},
  {'key': 'stroke',            'label': 'Stroke'},
  {'key': 'cancer',            'label': 'Cancer / Tumors'},
  {'key': 'anemia',            'label': 'Anemia'},
  {'key': 'angina',            'label': 'Angina'},
  {'key': 'asthma',            'label': 'Asthma'},
  {'key': 'emphysema',         'label': 'Emphysema'},
  {'key': 'bleeding_problems', 'label': 'Bleeding Problems'},
  {'key': 'blood_diseases',    'label': 'Blood Diseases'},
  {'key': 'head_injuries',     'label': 'Head Injuries'},
  {'key': 'arthritis',         'label': 'Arthritis / Rheumatism'},
];

// ─── Allergy Types ──────────────────────────────────────────────────────────
const List<Map<String, String>> kAllergyTypes = [
  {'key': 'lidocaine',  'label': 'Local Anesthetic (Lidocaine)'},
  {'key': 'penicillin', 'label': 'Penicillin Antibiotics'},
  {'key': 'sulfa',      'label': 'Sulfa Drugs'},
  {'key': 'aspirin',    'label': 'Aspirin'},
  {'key': 'latex',      'label': 'Latex'},
];

// ─── Intraoral Condition ────────────────────────────────────────────────────
class IntraoralCondition {
  final String key;
  final String label;
  final String symbol;
  const IntraoralCondition(this.key, this.label, this.symbol);
}

const List<IntraoralCondition> kIntraoralLegend = [
  IntraoralCondition('D',            'Decayed (Caries for Filling)',     'D'),
  IntraoralCondition('J',            'Jacket Crown',                    'J'),
  IntraoralCondition('M',            'Missing due to Carries',          'M'),
  IntraoralCondition('F',            'Filled',                          'F'),
  IntraoralCondition('extraction',   'Caries for Extraction',           '!'),
  IntraoralCondition('A',            'Amalgam Filling',                 'A'),
  IntraoralCondition('surgery',      'Surgery',                         'SUR'),
  IntraoralCondition('RF',           'Root Fragment',                   'RF'),
  IntraoralCondition('AB',           'Abutment',                        'AB'),
  IntraoralCondition('X',            'Extraction due to Carries',       'X'),
  IntraoralCondition('MO',           'Missing due to Other',            'MO'),
  IntraoralCondition('PP',           'Pontic',                          'PP'),
  IntraoralCondition('XO',           'Extraction Other Causes',         'XO'),
  IntraoralCondition('In',           'Inlay',                           'In'),
  IntraoralCondition('present',      'Present Teeth',                   '✓'),
  IntraoralCondition('Im',           'Impacted Tooth',                  'Im'),
  IntraoralCondition('FX',           'Fixed Composite',                 'FX'),
  IntraoralCondition('Cm',           'Congenitally Missing',            'Cm'),
  IntraoralCondition('period_screen','Periodical Screening',            'PS'),
  IntraoralCondition('Rm',           'Removable Denture',               'Rm'),
  IntraoralCondition('Sp',           'Supernumerary',                   'Sp'),
  IntraoralCondition('gingivitis',   'Gingivitis',                      'Gin'),
  IntraoralCondition('early_perio',  'Early Periodontics',              'EP'),
  IntraoralCondition('occlusion_app','Occlusion Appliances',            'OA'),
  IntraoralCondition('moderate_perio','Moderate Periodontics',          'MP'),
  IntraoralCondition('molar_class',  'Class (Molar)',                   'Cl'),
  IntraoralCondition('ortho_stay',   'Orthodontic Stayplate',           'OS'),
  IntraoralCondition('THD',          'Advanced Periodontics',           'TH'),
  IntraoralCondition('overjet',      'Overjet',                         'OJ'),
  IntraoralCondition('overbite',     'Overbite',                        'OB'),
  IntraoralCondition('midline_dev',  'Midline Deviation',               'MD'),
  IntraoralCondition('crossbite',    'Crossbite',                       'CB'),
  IntraoralCondition('others_cond',  'Others',                          'O'),
  IntraoralCondition('clenching',    'Clenching',                       'CL'),
  IntraoralCondition('cracking',     'Cracking',                        'CR'),
  IntraoralCondition('trismus',      'Trismus',                         'TR'),
  IntraoralCondition('muscle_spasm', 'Muscle Spasms',                   'MS'),
];

// ─── Teeth Numbers ──────────────────────────────────────────────────────────
const List<int> kPermanentTeeth = [
  18, 17, 16, 15, 14, 13, 12, 11,
  21, 22, 23, 24, 25, 26, 27, 28,
  31, 32, 33, 34, 35, 36, 37, 38,
  48, 47, 46, 45, 44, 43, 42, 41,
];

const List<String> kPrimaryTeeth = [
  'A','B','C','D','E','F','G','H','I','J',
  'K','L','M','N','O','P','Q','R','S','T',
];