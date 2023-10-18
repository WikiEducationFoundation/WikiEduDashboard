export const PageAssessmentGrades = {
  wikipedia: {
    en: {
      FA: {
        class: 'fa',
        pretty: 'FA',
        score: 100
      },
      FL: {
        class: 'fl',
        pretty: 'FL',
        score: 95
      },
      A: {
        class: 'a',
        pretty: 'A',
        score: 85
      },
      GA: {
        class: 'ga',
        pretty: 'GA',
        score: 80
      },
      B: {
        class: 'b',
        pretty: 'B',
        score: 60,
      },
      C: {
        class: 'c',
        pretty: 'C',
        score: 40,
      },
      Start: {
        class: 'start',
        pretty: 'S',
        score: 20,
      },
      Stub: {
        class: 'stub',
        pretty: 'S',
        score: 0
      },
      List: {
        class: 'list',
        pretty: 'List',
        score: -10
      }
    },
    ar: {
      'م.مخ': {
        class: 'fa',
        pretty: 'م.مخ',
        score: 100
      },
      أ: {
        class: 'ga',
        pretty: '|',
        score: 80,
      },
      ب: {
        class: 'b',
        pretty: 'ب',
        score: 60,
      },
      ج: {
        class: 'c',
        pretty: 'ج',
        score: 40
      },
      بداية: {
        class: 'start',
        pretty: 'بداية',
        score: 20,
      },
      بذرة: {
        class: 'stub',
        pretty: 'بذرة',
        score: 0
      }
    },
    fr: {
      AdQ: {
        class: 'fa',
        pretty: 'AdQ',
        score: 100,
      },
      BA: {
        class: 'ga',
        pretty: 'BA',
        score: 80
      },
      A: {
        class: 'b',
        pretty: 'A',
        score: 60,
      },
      B: {
        class: 'c',
        pretty: 'B',
        score: 40,
      },
      BD: {
        class: 'start',
        pretty: 'BD',
        score: 20,
      },
      ébauche: {
        class: 'stub',
        pretty: 'E',
        score: 0
      }
    },
    tr: {
      SM: {
        class: 'fa',
        pretty: 'SM',
        score: 100
      },
      KM: {
        class: 'ga',
        pretty: 'KM',
        score: 80
      },
      B: {
        class: 'b',
        pretty: 'B',
        score: 60,
      },
      C: {
        class: 'c',
        pretty: 'C',
        score: 40,
      },
      Başlangıç: {
        class: 'start',
        pretty: 'BA',
        score: 20,
      },
      Taslak: {
        class: 'stub',
        pretty: 'TA',
        score: 0,
      }
    },
    hu: {
      kitüntetett: {
        class: 'fa',
        pretty: 'KI',
        score: 100
      },
      színvonalas: {
        class: 'ga',
        pretty: 'S',
        score: 80
      },
      teljes: {
        class: 'b',
        pretty: 'TE',
        score: 60,
      },
      'jól használható': {
        class: 'c',
        pretty: 'JH',
        score: 40,
      },
      vázlatos: {
        class: 'start',
        pretty: 'VA',
        score: 20
      },
      születő: {
        class: 'stub',
        pretty: 'SZ',
        score: 0
      }
    },
  },
  wikivoyage: {
    en: {
      star: {
        class: 'fa',
        pretty: 'ST',
        score: 100,
      },
      guide: {
        class: 'ga',
        pretty: 'G',
        score: 80,
      },
      usuable: {
        class: 'b',
        pretty: 'U',
        score: 60,
      },
      outline: {
        class: 'start',
        pretty: 'OT',
        score: 20,
      },
      stub: {
        class: 'stub',
        pretty: 'S',
        score: 0,
      }
    }
  }
};

// Most common, reused weighting scheme
const EnWikiWeights = {
  FA: 100,
  GA: 80,
  B: 60,
  C: 40,
  Start: 20,
  Stub: 0
};

const FrWikiWeights = {
  adq: 100,
  ba: 80,
  a: 60,
  b: 40,
  bd: 20,
  e: 0
};
const TrWikiWeights = {
  sm: 100,
  km: 80,
  b: 60,
  c: 40,
  baslagıç: 20,
  taslak: 0,
};
const RuWikiWeights = {
  ИС: 100,
  ДС: 80,
  ХС: 80,
  I: 60,
  II: 40,
  III: 20,
  IV: 0
};
const PtWikiWeights = {
  6: 100,
  5: 80,
  4: 60,
  3: 40,
  2: 20,
  1: 0 };
const UkWikiWeights = {
  ДС: 100,
  ВС: 80,
  I: 60,
  II: 40,
  III: 20,
  IV: 0 };
const SvWikiWeights = {
  u: 100,
  b: 90,
  r: 80,
  s: 0 };
const NlWikiWeights = {
  A: 100,
  B: 75,
  C: 50,
  D: 25,
  E: 0
};

export const LiftwingWeights = {
  en: EnWikiWeights,
  simple: EnWikiWeights,
  fa: EnWikiWeights,
  eu: EnWikiWeights,
  fr: FrWikiWeights,
  tr: TrWikiWeights,
  ru: RuWikiWeights,
  uk: UkWikiWeights,
  gl: EnWikiWeights,
  sv: SvWikiWeights,
  nl: NlWikiWeights,
  pt: PtWikiWeights,
};

// Update the server side mapping in sync.
export const ORESSupportedWiki = {
  projects: ['wikipedia', 'wikidata'],
  languages: ['en', 'gl', 'fr', 'simple', 'tr', 'ru', 'eu', 'fa', 'sv']
};

// Refer: https://xtools.wmflabs.org/api/project/assessments
export const PageAssessmentSupportedWiki = {
  wikipedia: ['ar', 'en', 'hu', 'fr', 'tr'],
  wikivoyage: ['en'],
};
