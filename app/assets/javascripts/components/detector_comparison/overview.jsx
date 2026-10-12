/* eslint-disable i18next/no-literal-string */
// English-only admin research page: no i18n, by decision (see descriptions.js).
import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import { Link } from 'react-router-dom';
import {
  AUTHORSHIP_NOTE, BASELINE, DETECTOR_ORDER, DETECTORS, FAMILIES, INTRO, MODEL_GROUPS
} from './descriptions';
import { ALERT_KEY, detectorsIn, fetchOverview, isAgpedia, isHuman, percent, shade, tally, verdictFor } from './data';
import VerdictChip from './verdict_chip';
import VerdictMatrix from './verdict_matrix';

const RateCell = ({ k, n }) => {
  if (!n) return <td className="detector-comparison__none">–</td>;
  return (
    <td className="detector-comparison__rate" style={shade(k / n)}>
      <span className="detector-comparison__cell-rate">{percent(k, n)}</span>
      <span className="detector-comparison__cell-count">{k}/{n}</span>
    </td>
  );
};

RateCell.propTypes = { k: PropTypes.number, n: PropTypes.number };

// One row per sample family, with each detector's share flagged; the
// baseline row comes from the server's per-text tally of the whole baseline.
const FamilyTable = ({ units, baseline }) => {
  const detectors = DETECTOR_ORDER.filter(key => detectorsIn(units).includes(key)
    || (key === ALERT_KEY ? baseline['Pangram 4'] : baseline[key]));
  const familyUnits = key => (key === 'paired_human' ? units.filter(isHuman) : units.filter(unit => unit.sample === key));
  const families = FAMILIES.filter(family => familyUnits(family.key).length);
  const known = FAMILIES.map(family => family.key);
  const otherSamples = [...new Set(units.filter(unit => !isHuman(unit)).map(unit => unit.sample))].filter(sample => !known.includes(sample));
  const baselineCount = (key) => {
    const counts = key === ALERT_KEY ? baseline['Pangram 4'] : baseline[key];
    if (!counts) return {};
    return { k: key === ALERT_KEY ? counts.alerts : counts.flagged, n: counts.texts };
  };

  return (
    <div className="detector-comparison__scroll">
      <table className="table detector-comparison__families">
        <thead>
          <tr>
            <th scope="col">Texts</th>
            {detectors.map(key => <th scope="col" key={key} title={DETECTORS[key]?.description}>{DETECTORS[key]?.label || key}</th>)}
          </tr>
        </thead>
        <tbody>
          <tr className="detector-comparison__baseline-row">
            <th scope="row">{BASELINE.label}<small>{BASELINE.description}</small></th>
            {detectors.map(key => <RateCell key={key} {...baselineCount(key)} />)}
          </tr>
          {families.map(family => (
            <tr key={family.key}>
              <th scope="row">{family.label}<small>{family.description}</small></th>
              {detectors.map(key => <RateCell key={key} {...tally(familyUnits(family.key), key)} />)}
            </tr>
          ))}
          {otherSamples.map(sample => (
            <tr key={sample}>
              <th scope="row">{sample}</th>
              {detectors.map(key => <RateCell key={key} {...tally(familyUnits(sample), key)} />)}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

FamilyTable.propTypes = { units: PropTypes.array.isRequired, baseline: PropTypes.object.isRequired };

const AgpediaTable = ({ units }) => {
  const articles = units.filter(unit => isAgpedia(unit))
    .sort((a, b) => (a.factors.topic || '').localeCompare(b.factors.topic || '') || (a.factors.excerpt || '').localeCompare(b.factors.excerpt || ''));
  const detectors = detectorsIn(articles);
  return (
    <div className="detector-comparison__scroll">
      <table className="table table--hoverable detector-comparison__agpedia">
        <thead>
          <tr>
            <th scope="col">Article</th>
            <th scope="col">Part</th>
            <th scope="col">Operator</th>
            <th scope="col">Agent</th>
            <th scope="col">Words</th>
            {detectors.map(key => <th scope="col" key={key}>{DETECTORS[key]?.short || key}</th>)}
          </tr>
        </thead>
        <tbody>
          {articles.map(unit => (
            <tr key={unit.id}>
              <td><Link to={`/detector_comparison/units/${unit.id}`}>{unit.factors.topic}</Link></td>
              <td>{unit.factors.excerpt}</td>
              <td>{unit.factors.author}</td>
              <td>{unit.factors.agent}</td>
              <td>{unit.words}</td>
              {detectors.map(key => <td key={key}><VerdictChip verdict={verdictFor(unit, key)} /></td>)}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

AgpediaTable.propTypes = { units: PropTypes.array.isRequired };

export const AuthorshipNote = ({ generatedAt }) => (
  <footer className="detector-comparison__footer">
    <p>{AUTHORSHIP_NOTE}</p>
    {generatedAt && <p>Data as of {new Date(generatedAt).toLocaleString()}.</p>}
  </footer>
);

AuthorshipNote.propTypes = { generatedAt: PropTypes.string };

const Overview = () => {
  const [data, setData] = useState(null);
  const [failed, setFailed] = useState(false);
  useEffect(() => {
    fetchOverview().then(setData).catch(() => setFailed(true));
  }, []);

  if (failed) return <div className="container detector-comparison"><p>The comparison data could not be loaded.</p></div>;
  if (!data) return <div className="container detector-comparison"><p>Loading…</p></div>;

  return (
    <div className="container detector-comparison">
      <h1>AI detector comparison</h1>
      {INTRO.map(paragraph => <p key={paragraph} className="detector-comparison__intro">{paragraph}</p>)}

      <section>
        <h2>Results by sample</h2>
        <FamilyTable units={data.units} baseline={data.baseline} />
      </section>

      <section>
        <h2>Generated texts by model and condition</h2>
        {MODEL_GROUPS.map(group => <p key={group.key} className="detector-comparison__help"><strong>{group.label}:</strong> {group.description}</p>)}
        <VerdictMatrix units={data.units} />
      </section>

      <section>
        <h2>Agpedia articles</h2>
        <AgpediaTable units={data.units} />
      </section>

      <section>
        <h2>Detectors</h2>
        <dl className="detector-comparison__detectors">
          {DETECTOR_ORDER.filter(key => DETECTORS[key]).map(key => (
            <React.Fragment key={key}>
              <dt>{DETECTORS[key].label}{DETECTORS[key].research && <span className="detector-comparison__research"> research only</span>}</dt>
              <dd>{DETECTORS[key].description}</dd>
            </React.Fragment>
          ))}
        </dl>
      </section>

      <AuthorshipNote generatedAt={data.generated_at} />
    </div>
  );
};

export default Overview;
