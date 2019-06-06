const projects = [
  'wikipedia',
  'wikibooks',
  'wikimedia',
  'wikinews',
  'wikiquote',
  'wikisource',
  'wikiversity',
  'wikivoyage',
  'wiktionary'
];
const languages = [
  'aa', 'ab', 'ace', 'ady', 'af', 'ak', 'als', 'am', 'an', 'ang', 'ar', 'arc', 'arz', 'as', 'ast', 'atj', 'av', 'ay', 'az', 'azb',
  'ba', 'bar', 'bat-smg', 'bcl', 'be', 'be-tarask', 'be-x-old', 'bg', 'bh', 'bi', 'bjn', 'bm', 'bn', 'bo', 'bpy', 'br', 'bs',
  'bug', 'bxr', 'ca', 'cbk-zam', 'cdo', 'ce', 'ceb', 'ch', 'cho', 'chr', 'chy', 'ckb', 'cmn', 'co', 'commons', 'cr', 'crh', 'cs', 'csb', 'cu',
  'cv', 'cy', 'cz', 'da', 'de', 'din', 'diq', 'dk', 'dsb', 'dty', 'dv', 'dz', 'ee', 'egl', 'el', 'eml', 'en', 'eo', 'epo', 'es', 'et', 'eu', 'ext', 'fa',
  'ff', 'fi', 'fiu-vro', 'fj', 'fo', 'fr', 'frp', 'frr', 'fur', 'fy', 'ga', 'gag', 'gan', 'gd', 'gl', 'glk', 'gn', 'gom', 'gor', 'got', 'gsw',
  'gu', 'gv', 'ha', 'hak', 'haw', 'he', 'hi', 'hif', 'ho', 'hr', 'hsb', 'ht', 'hu', 'hy', 'hz', 'ia', 'id', 'ie', 'ig', 'ii', 'ik', 'ilo',
  'incubator', 'inh', 'io', 'is', 'it', 'iu', 'ja', 'jam', 'jbo', 'jp', 'jv', 'ka', 'kaa', 'kab', 'kbd', 'kbp', 'kg', 'ki', 'kj', 'kk', 'kl', 'km', 'kn', 'ko',
  'koi', 'kr', 'krc', 'ks', 'ksh', 'ku', 'kv', 'kw', 'ky', 'la', 'lad', 'lb', 'lbe', 'lez', 'lfn', 'lg', 'li', 'lij', 'lmo', 'ln', 'lo', 'lrc', 'lt',
  'ltg', 'lv', 'lzh', 'mai', 'map-bms', 'mdf', 'mg', 'mh', 'mhr', 'mi', 'min', 'minnan', 'mk', 'ml', 'mn', 'mo', 'mr', 'mrj', 'ms', 'mt',
  'mus', 'mwl', 'my', 'myv', 'mzn', 'na', 'nah', 'nan', 'nap', 'nb', 'nds', 'nds-nl', 'ne', 'new', 'ng', 'nl', 'nn', 'no', 'nov', 'nrm',
  'nso', 'nv', 'ny', 'oc', 'olo', 'om', 'or', 'os', 'pa', 'pag', 'pam', 'pap', 'pcd', 'pdc', 'pfl', 'pi', 'pih', 'pl', 'pms', 'pnb', 'pnt', 'ps',
  'pt', 'qu', 'rm', 'rmy', 'rn', 'ro', 'roa-rup', 'roa-tara', 'ru', 'rue', 'rup', 'rw', 'sa', 'sah', 'sat', 'sc', 'scn', 'sco', 'sd', 'se',
  'sg', 'sgs', 'sh', 'si', 'simple', 'sk', 'sl', 'sm', 'sn', 'so', 'sq', 'sr', 'srn', 'ss', 'st', 'stq', 'su', 'sv', 'sw', 'szl', 'ta', 'tcy', 'te',
  'tet', 'tg', 'th', 'ti', 'tk', 'tl', 'tn', 'to', 'tpi', 'tr', 'ts', 'tt', 'tum', 'tw', 'ty', 'tyv', 'udm', 'ug', 'uk', 'ur', 'uz', 've',
  'vec', 'vep', 'vi', 'vls', 'vo', 'vro', 'w', 'wa', 'war', 'wikipedia', 'wo', 'wuu', 'xal', 'xh', 'xmf', 'yi', 'yo', 'yue', 'za',
  'zea', 'zh', 'zh-cfr', 'zh-classical', 'zh-cn', 'zh-min-nan', 'zh-tw', 'zh-yue', 'zu'
];
const WIKI_OPTIONS = languages.map(language =>
  projects.map((project) => {
    const value = { language, project };
    const label = `${language}.${project}.org`;
    return { value, label };
  })
).reduce((a, b) => a.concat(b));
// Wikidata is multilingual with English as the default language and therefore has
// a custom label so it is more intuitive.
WIKI_OPTIONS.unshift({ value: { language: 'en', project: 'wikidata' }, label: 'www.wikidata.org' });
// Wikisource has a standalone www.wikisource.org in addition to language based sites like es.wikisource.org
WIKI_OPTIONS.unshift({ value: { language: 'en', project: 'wikisource' }, label: 'www.wikisource.org' });
// We are inserting the above at first so users are aware of this option and it doesn't disappear
// among the limited results

export default WIKI_OPTIONS;
