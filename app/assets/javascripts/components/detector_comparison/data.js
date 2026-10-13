import request, { ensureOk } from '../../utils/request';
import { DETECTOR_ORDER, MODELS, CONDITION_ORDER, REFERENCE_ROWS } from './descriptions';

export const ALERT_KEY = 'Pangram 4 alert';

// Detectors drawn as bars in each grid cell, in a fixed order, each with a fixed color from the
// validated categorical palette (dataviz reference palette, slots 1–5).
export const BAR_DETECTORS = [
  { key: 'Pangram 4', id: 'p4', color: '#2a78d6' },
  { key: 'Originality AI Allowance 40', id: 'a40', color: '#eb6834' },
  { key: 'Originality AI Allowance 15', id: 'a15', color: '#1baf7a' },
  { key: 'Open Pangram EditLens Llama', id: 'opl', color: '#eda100' },
  { key: 'Open Pangram EditLens RoBERTa', id: 'opr', color: '#e87ba4' },
];

export const INDEX_PATH = '/detector_comparison';
export const datasetPath = key => `${INDEX_PATH}/${key === 'known_human' ? 'known_human' : 'topics'}`;

// Each dataset's data is large and the same for every view, so it is fetched once per page load.
const fetched = {};
const fetchOnce = (url, what) => {
  if (!fetched[url]) {
    fetched[url] = request(url)
      .then(response => ensureOk(response, what))
      .then(response => response.json())
      .catch((error) => { delete fetched[url]; throw error; });
  }
  return fetched[url];
};
export const fetchIndex = () => fetchOnce(`${INDEX_PATH}.json`, 'detector comparison');
export const fetchOverview = () => fetchOnce(`${datasetPath('topics')}.json`, 'detector comparison topics');
export const fetchKnownHuman = () => fetchOnce(`${datasetPath('known_human')}.json`, 'detector comparison known human');

export const fetchUnit = id => request(`/detector_comparison/units/${id}.json`)
  .then(response => ensureOk(response, 'detector comparison unit'))
  .then(response => response.json());

// A unit's result for one detector, or for the Dashboard's alert rule on Pangram 4.
export const verdictFor = (unit, key) => {
  if (key === ALERT_KEY) {
    const pangram = unit.scores['Pangram 4'];
    return pangram ? { flagged: pangram.alert, label: pangram.alert ? 'Alert' : 'No alert', score: pangram.max } : null;
  }
  const score = unit.scores[key];
  if (!score) return null;
  return { flagged: score.flagged, label: score.label, score: score.document ?? score.mean };
};

export const tally = (units, key) => {
  const verdicts = units.map(unit => verdictFor(unit, key)).filter(Boolean);
  return { n: verdicts.length, k: verdicts.filter(verdict => verdict.flagged).length };
};

// Detectors with a result for any of the units, known ones first in a fixed order.
export const detectorsIn = (units) => {
  const present = new Set(units.flatMap(unit => Object.keys(unit.scores)));
  if (present.has('Pangram 4')) present.add(ALERT_KEY);
  const known = DETECTOR_ORDER.filter(key => present.has(key));
  return known.concat([...present].filter(key => !DETECTOR_ORDER.includes(key)).sort());
};

const ordered = (values, order) => {
  const present = [...new Set(values.filter(Boolean))];
  return order.filter(value => present.includes(value)).concat(present.filter(value => !order.includes(value)).sort());
};

export const modelsIn = units => ordered(units.map(unit => unit.factors.model), Object.keys(MODELS));
export const conditionsIn = units => ordered(units.map(unit => unit.condition), CONDITION_ORDER);
export const topicsIn = units => [...new Set(units.map(unit => unit.factors.topic).filter(Boolean))].sort();

export const isGenerated = unit => unit.provenance === 'synthetic';
export const isAgpedia = unit => unit.provenance === 'agpedia';
export const isHuman = unit => unit.ground_truth === 'human';

// Which reference row a text belongs to (see REFERENCE_ROWS), or null for a generated text.
export const referenceKey = (unit, pairedIds) => {
  if (isAgpedia(unit)) return 'reference:agpedia';
  if (pairedIds.has(unit.id)) return 'reference:human';
  const row = REFERENCE_ROWS.find(reference => reference.version && reference.version === unit.factors.version);
  return row ? row.key : null;
};
export const pairedIdsOf = units => new Set(units.map(unit => unit.paired_unit_id).filter(Boolean));

// The topic of a paired human text, taken from the generated texts that point to it.
export const topicOfPair = (units, id) => units.find(unit => unit.paired_unit_id === id)?.factors.topic;

export const percent = (k, n) => (n ? `${Math.round((100 * k) / n)}%` : '–');
export const formatScore = score => (score === null || score === undefined ? '–' : Number(score).toFixed(3));

// Shading for a share or a score in [0, 1]: blue-violet, stronger as it rises. Capped so the
// page's dark text keeps at least 4.5:1 contrast on the darkest shade.
export const shade = value => ({
  backgroundColor: `rgba(82, 72, 175, ${(0.04 + (0.5 * value)).toFixed(3)})`,
});
