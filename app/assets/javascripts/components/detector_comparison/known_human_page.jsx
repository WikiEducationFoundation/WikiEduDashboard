/* eslint-disable i18next/no-literal-string */
// English-only admin research page: no i18n, by decision (see descriptions.js). Written by
// Claude Code at Sage Ross's direction (2026-10-13).
import React, { useEffect, useMemo, useState } from 'react';
import PropTypes from 'prop-types';
import { Link } from 'react-router-dom';
import { DETECTORS, EXPLANATIONS_AUTHORSHIP_NOTE } from './descriptions';
import { BAR_DETECTORS, fetchKnownHuman, formatScore, verdictFor } from './data';
import { useSelection } from './selection';
import { ActiveView, TABLE_ID } from './curated_views';
import { DetectorList } from './explanations';
import DatasetHeader from './dataset_header';
import AuthorshipNote, { AuthorshipDagger } from './authorship_note';
import VerdictChip from './verdict_chip';

const FIRST_ROWS = 50;
const SEASONS = ['spring', 'summer', 'fall'];

const termOrder = (term) => {
  const [season, year] = (term || '').split('_');
  return (Number(year) || 0) * 10 + SEASONS.indexOf(season);
};
const termLabel = term => (term ? term.replace('_', ' ').replace(/^\w/, letter => letter.toUpperCase()) : '–');

// The upper end of the exact (Clopper–Pearson) 95% interval on a rate of k in n: the highest
// rate the sample cannot rule out.
const binomialCdf = (k, n, p) => {
  let term = (1 - p) ** n;
  let sum = term;
  for (let i = 0; i < k; i += 1) {
    term *= ((n - i) / (i + 1)) * (p / (1 - p));
    sum += term;
  }
  return sum;
};
const upperBound = (k, n) => {
  if (k >= n) return 1;
  let [low, high] = [k / n, 1];
  for (let step = 0; step < 60; step += 1) {
    const middle = (low + high) / 2;
    if (binomialCdf(k, n, middle) > 0.025) low = middle;
    else high = middle;
  }
  return low;
};

const scoreOf = (unit, detector) => verdictFor(unit, detector.key);
const label = detector => DETECTORS[detector.key]?.label || detector.key;

// Each detector's record on the known-human texts.
const Summary = ({ units, detectors }) => (
  <div className="detector-comparison__scroll">
    <table className="table detector-comparison__baseline-summary">
      <thead>
        <tr>
          <th scope="col">Detector</th>
          <th scope="col">Texts scored</th>
          <th scope="col">Detected as AI</th>
          <th scope="col">Plausible maximum rate</th>
          <th scope="col">Highest score</th>
          <th scope="col">99th percentile</th>
        </tr>
      </thead>
      <tbody>
        {detectors.map((detector) => {
          const verdicts = units.map(unit => scoreOf(unit, detector)).filter(Boolean);
          const scores = verdicts.map(verdict => verdict.score ?? 0).sort((a, b) => a - b);
          const detected = verdicts.filter(verdict => verdict.flagged).length;
          return (
            <tr key={detector.id}>
              <th scope="row">{label(detector)}</th>
              <td>{verdicts.length}</td>
              <td>{detected}</td>
              <td>{verdicts.length ? `${(100 * upperBound(detected, verdicts.length)).toFixed(2)}%` : '–'}</td>
              <td>{scores.length ? formatScore(scores[scores.length - 1]) : '–'}</td>
              <td>{scores.length ? formatScore(scores[Math.min(scores.length - 1, Math.floor(0.99 * scores.length))]) : '–'}</td>
            </tr>
          );
        })}
      </tbody>
    </table>
  </div>
);

Summary.propTypes = { units: PropTypes.array.isRequired, detectors: PropTypes.array.isRequired };

// Every text with each shown detector's score, highest first; a detector's verdict is shown
// only where it found AI.
const Texts = ({ units, detectors }) => {
  const [sortBy, setSortBy] = useState(null);
  const [showAll, setShowAll] = useState(false);
  const key = unit => (sortBy
    ? scoreOf(unit, sortBy)?.score ?? -1
    : Math.max(-1, ...detectors.map(detector => scoreOf(unit, detector)?.score ?? -1)));
  const sorted = [...units].sort((a, b) => key(b) - key(a));
  const rows = showAll ? sorted : sorted.slice(0, FIRST_ROWS);
  const sortButton = (detector, text) => (
    <button
      type="button" className="detector-comparison__sort" aria-pressed={sortBy?.id === detector?.id}
      onClick={() => setSortBy(detector)}
    >
      {text}
    </button>
  );

  return (
    <>
      <div className="detector-comparison__scroll">
        <table className="table detector-comparison__baseline-texts">
          <thead>
            <tr>
              <th scope="col">Text</th>
              <th scope="col">Term</th>
              <th scope="col">Words</th>
              {detectors.map(detector => <th scope="col" key={detector.id}>{sortButton(detector, label(detector))}</th>)}
            </tr>
          </thead>
          <tbody>
            {rows.map(unit => (
              <tr key={unit.id}>
                <th scope="row">
                  <Link to={`/detector_comparison/units/${unit.id}`}>{unit.title || `Text ${unit.id}`}</Link>
                  {unit.url && <> · <a href={unit.url}>{unit.url.includes('diff=') ? 'diff' : 'revision'}</a></>}
                </th>
                <td>{termLabel(unit.term)}</td>
                <td>{unit.words?.toLocaleString()}</td>
                {detectors.map((detector) => {
                  const verdict = scoreOf(unit, detector);
                  return (
                    <td key={detector.id} className="detector-comparison__baseline-score">
                      {verdict ? formatScore(verdict.score) : '–'}
                      {verdict?.flagged && <> <VerdictChip verdict={verdict} /></>}
                    </td>
                  );
                })}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <p className="detector-comparison__help">
        {sortBy ? <>Sorted by {label(sortBy)}. {sortButton(null, 'Sort by the highest score shown')}</> : 'Sorted by the highest score among the detectors shown.'}
      </p>
      {!showAll && sorted.length > FIRST_ROWS && (
        <button type="button" className="button" onClick={() => setShowAll(true)}>Show all {sorted.length.toLocaleString()} texts</button>
      )}
    </>
  );
};

Texts.propTypes = { units: PropTypes.array.isRequired, detectors: PropTypes.array.isRequired };

const Explanations = ({ terms }) => (
  <section className="detector-comparison__explanations">
    <h2>How to read this page<AuthorshipDagger /></h2>

    <h3>The texts</h3>
    <p>
      Each text is what was added to one English Wikipedia article over the term of a Wiki Education course, before ChatGPT&apos;s
      release: the difference between the article at the start and at the end of the course, or the whole article if it did
      not exist at the start. Anything another editor added in that time is included too; all of it predates ChatGPT, so all
      of it is human-written. For each term{terms && ` (${terms})`}, the texts are a random sample of the articles that gained
      substantial text in a course. Fall 2022 is left out because it overlapped ChatGPT&apos;s release, and texts from other languages are
      left out so that every detector is judged on the same texts. Redirect pages are left out too: one sampled article had become a
      redirect by the end of its course, so its text was the redirect template&apos;s boilerplate rather than anyone&apos;s writing.
    </p>

    <h3>The tables</h3>
    <ul>
      <li>
        <strong>Detected as AI</strong>: how many texts each detector&apos;s own verdict found AI in. Any verdict short of human
        counts: AI or Mixed for Pangram 4, AI for Originality.ai, and AI or an AI-edited level for Open Pangram. Every one is a
        false positive.
      </li>
      <li>
        <strong>Plausible maximum rate</strong>: the highest false-positive rate the results cannot rule out, the upper end of
        an exact 95% confidence interval (Clopper–Pearson). With none detected in about 580 texts it is about 0.6%; more texts
        would bring it down.
      </li>
      <li>
        <strong>Scores</strong>: each detector&apos;s whole-text AI score from 0 to 1, as on the 16-topic table. Scores far below
        the point where a detector calls text AI leave it more margin than scores close to it. Open Pangram&apos;s score is the
        expected level of AI involvement, so even text it calls human usually scores above zero; compare its scores only with
        its own.
      </li>
      <li>
        <strong>Texts</strong>: listed from the highest score down; select a detector&apos;s heading to sort by its score, and a
        text to see it with each detector&apos;s full result.
      </li>
      <li>
        <strong>Copies</strong>: Originality.ai first scored 30 of these texts in September 2026, as copies in a separate sample.
        Those results count for the texts here.
      </li>
    </ul>

    <DetectorList />
  </section>
);

Explanations.propTypes = { terms: PropTypes.string };

// The known-human dataset: pre-ChatGPT student writing, for measuring false positives.
const KnownHumanPage = () => {
  const [data, setData] = useState(null);
  const [failed, setFailed] = useState(false);
  const options = useMemo(() => ({ models: [], strategies: [], topics: [], detectors: BAR_DETECTORS.map(detector => detector.id) }), []);
  const { selection, toggle } = useSelection(options);
  useEffect(() => {
    fetchKnownHuman().then(setData).catch(() => setFailed(true));
  }, []);

  if (failed) return <div className="container detector-comparison"><p>The comparison data could not be loaded.</p></div>;
  if (!data) return <div className="container detector-comparison"><DatasetHeader current="known_human" /><p>Loading…</p></div>;

  const detectors = BAR_DETECTORS.filter(detector => selection.detectors.includes(detector.id));
  const terms = [...new Set(data.units.map(unit => unit.term).filter(Boolean))].sort((a, b) => termOrder(a) - termOrder(b));
  const termRange = terms.length ? `${termLabel(terms[0])} to ${termLabel(terms[terms.length - 1])}` : null;

  return (
    <div className="container detector-comparison">
      <DatasetHeader current="known_human" />
      <section id={TABLE_ID}>
        <ActiveView views={data.intro?.views || []} dataset="known_human" />
        <fieldset className="detector-comparison__filter detector-comparison__filter--inline">
          <legend>Detectors</legend>
          {BAR_DETECTORS.map(detector => (
            <label key={detector.id} htmlFor={`dc-human-${detector.id}`} className="detector-comparison__filter-option">
              <input
                id={`dc-human-${detector.id}`} type="checkbox" checked={selection.detectors.includes(detector.id)}
                onChange={() => toggle('detectors', detector.id)}
              />
              <svg width="10" height="10" aria-hidden="true"><rect width="10" height="10" rx="2" fill={detector.color} /></svg>
              {label(detector)}
            </label>
          ))}
        </fieldset>
        <h2>{data.units.length.toLocaleString()} texts{termRange && `, ${termRange}`}</h2>
        <Summary units={data.units} detectors={detectors} />
        <Texts units={data.units} detectors={detectors} />
      </section>

      <Explanations terms={termRange} />
      <AuthorshipNote generatedAt={data.generated_at} note={EXPLANATIONS_AUTHORSHIP_NOTE} />
    </div>
  );
};

export default KnownHumanPage;
