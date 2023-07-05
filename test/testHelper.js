import { createStore, applyMiddleware } from 'redux';
import thunk from 'redux-thunk';
import reducer from '../app/assets/javascripts/reducers';

const mock = require('jest-mock');

const jsdom = require('jsdom');

const { JSDOM } = jsdom;

global.document = new JSDOM('<!doctype html><html><body><div data-current_user=\'{ "admin": false, "id": null }\' id=\'react_root\'></div></body></html>', {
  url: 'http://localhost',
  skipWindowCheck: true
});
global.window = document.defaultView;
global.window.scrollTo = mock.fn(); // scrollTo is not implemented by JSDOM, so we mock it.
global.navigator = global.window.navigator;

const sinon = require('sinon');
const $ = require('jquery');

const chai = require('chai');
const sinonChai = require('sinon-chai');

const reduxStore = createStore(reducer, applyMiddleware(thunk));

global.reduxStore = reduxStore;
global.$ = $;
global.sinon = sinon;
global.Features = {};
global.currentUser = {};
global.WikiProjects = JSON.stringify([
  'wikipedia',
  'wikibooks',
  'wikidata',
  'wikimedia',
  'wikinews',
  'wikiquote',
  'wikisource',
  'wikiversity',
  'wikivoyage',
  'wiktionary'
]);
global.WikiLanguages = JSON.stringify([
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
]);
global.ProjectNamespaces = JSON.stringify({ wikipedia: [0, 2] });

I18n.store(window.stores);

chai.use(sinonChai);
