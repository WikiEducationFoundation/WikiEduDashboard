/* eslint-disable i18next/no-literal-string */
// English-only admin research page: no i18n, by decision (see descriptions.js).
import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import { useLocation } from 'react-router-dom';
import { DETECTORS, EXPLANATIONS_AUTHORSHIP_NOTE, FAMILIES } from './descriptions';
import { detectorsIn, fetchOverview, isGenerated, isHuman, pairedIdsOf, percent, referenceKey, shade, tally } from './data';
import TopicMatrix from './topic_matrix';
import { ActiveView, TABLE_ID } from './curated_views';
import Explanations from './explanations';
import DatasetHeader from './dataset_header';
import AuthorshipNote from './authorship_note';

const RateCell = ({ k, n }) => {
  if (!n) return <td className="detector-comparison__none">–</td>;
  return (
    <td className="detector-comparison__rate" style={shade(k / n)} title={`${k} of ${n}`}>
      <span className="detector-comparison__cell-rate">{percent(k, n)}</span>
      <span className="detector-comparison__cell-count">{k}/{n}</span>
    </td>
  );
};

RateCell.propTypes = { k: PropTypes.number, n: PropTypes.number };

// One row per group of texts, with each detector's share flagged. Columns are
// the detectors that scored the AI-written texts.
const GroupTable = ({ units }) => {
  const detectors = detectorsIn(units.filter(unit => !isHuman(unit)));
  const pairedIds = pairedIdsOf(units.filter(isGenerated));
  const groupUnits = key => (key.startsWith('reference:')
    ? units.filter(unit => !isGenerated(unit) && referenceKey(unit, pairedIds) === key)
    : units.filter(unit => unit.sample === key));
  const known = FAMILIES.map(family => family.key);
  const other = [...new Set(units.filter(isGenerated).map(unit => unit.sample))]
    .filter(sample => !known.includes(sample))
    .map(sample => ({ key: sample, label: sample }));
  const groups = FAMILIES.concat(other).filter(group => groupUnits(group.key).length);

  return (
    <div className="detector-comparison__scroll">
      <table className="table detector-comparison__groups">
        <thead>
          <tr>
            <th scope="col">Texts</th>
            {detectors.map(key => <th scope="col" key={key} title={DETECTORS[key]?.description}>{DETECTORS[key]?.label || key}</th>)}
          </tr>
        </thead>
        <tbody>
          {groups.map(group => (
            <tr key={group.key}>
              <th scope="row">{group.label}{group.description && <small>{group.description}</small>}</th>
              {detectors.map(key => <RateCell key={key} {...tally(groupUnits(group.key), key)} />)}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

GroupTable.propTypes = { units: PropTypes.array.isRequired };

// The 16-topic dataset: the conclusion the table is showing, the table with its collapsed
// selectors, then how to read it.
const TopicsDataset = () => {
  const [data, setData] = useState(null);
  const [failed, setFailed] = useState(false);
  useEffect(() => {
    fetchOverview().then(setData).catch(() => setFailed(true));
  }, []);
  // In-page links such as #open-weight-ladder in a view's description: the router does not
  // scroll to them, so scroll once the page has rendered.
  const { hash } = useLocation();
  useEffect(() => {
    if (data && hash) document.getElementById(decodeURIComponent(hash.slice(1)))?.scrollIntoView();
  }, [data, hash]);

  if (failed) return <div className="container detector-comparison"><p>The comparison data could not be loaded.</p></div>;
  if (!data) return <div className="container detector-comparison"><p>Loading…</p></div>;

  const views = data.intro?.views || [];
  return (
    <div className="container detector-comparison">
      <DatasetHeader current="topics" />
      <section id={TABLE_ID}>
        <ActiveView views={views} dataset="topics" />
        <TopicMatrix units={data.units} />
      </section>

      <Explanations prompts={data.prompts}>
        <details>
          <summary><h3 className="detector-comparison__summary-heading">Totals by group</h3></summary>
          <GroupTable units={data.units} />
        </details>
      </Explanations>

      <AuthorshipNote generatedAt={data.generated_at} note={EXPLANATIONS_AUTHORSHIP_NOTE} />
    </div>
  );
};

export default TopicsDataset;
