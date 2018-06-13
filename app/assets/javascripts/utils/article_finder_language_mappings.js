export const PageAssessmentGrades = {
  en: {
    FA: {
      class: 'fa',
      pretty: 'FA',
      score: 100
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
};

export const WP10Weights = {
  en: {
    FA: 100,
    GA: 80,
    B: 60,
    C: 40,
    Start: 20,
    Stub: 0
  },
  fr: {
    adq: 100,
    ba: 80,
    a: 60,
    b: 40,
    bd: 20,
    e: 0,
  },
  tr: {
    sm: 100,
    km: 80,
    b: 60,
    c: 40,
    baslagıç: 20,
    taslak: 0,
  },
  simple: {
    FA: 100,
    GA: 80,
    B: 60,
    C: 40,
    Start: 20,
    Stub: 0
  },
  ru: {
    ИС: 100,
    ДС: 80,
    ХС: 80,
    I: 60,
    II: 40,
    III: 20,
    IV: 0
  }
};

export const ORESSupportedWiki = {
  projects: 'wikipedia',
  languages: ['en', 'fr', 'simple', 'tr', 'ru']
};

export const PageAssessmentSupportedWiki = {
  languages: ['ar', 'en', 'hu', 'fr', 'tr'],
};
