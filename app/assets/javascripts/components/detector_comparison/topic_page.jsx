/* eslint-disable i18next/no-literal-string */
// English-only research page: no i18n, by decision (see descriptions.js).
import React, { useEffect, useMemo, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { AVERAGE_MODELS, AVERAGE_ROW, CONDITIONS, DEFAULT_SELECTION, DETECTORS, MODELS, REFERENCE_ROWS } from './descriptions';
import { BAR_DETECTORS, conditionsIn, datasetPath, fetchOverview, isGenerated, modelsIn } from './data';
import { AverageBars, averageValues, BarLegend, MiniBars, Tooltip, unitValues, useCellTooltip, valuesLabel } from './bars';
import { conditionLabel, modelLabel, referenceRows } from './topic_matrix';
import AuthorshipNote, { CreditsDagger } from './authorship_note';

const AVERAGE = 'average';
const wikipediaUrl = topic => `https://en.wikipedia.org/wiki/${encodeURIComponent(topic.replace(/ /g, '_'))}`;

// Every text on one topic: a row per prompt strategy and a column per model, with the
// average across the current models first, and the topic's reference texts above.
const TopicPage = () => {
  const { topic } = useParams();
  const [data, setData] = useState(null);
  const [failed, setFailed] = useState(false);
  const [selected, setSelected] = useState(DEFAULT_SELECTION.detectors);
  const { hover, show, hide } = useCellTooltip();
  useEffect(() => { fetchOverview().then(setData).catch(() => setFailed(true)); }, []);

  const texts = useMemo(() => {
    if (!data) return null;
    const generated = data.units.filter(unit => isGenerated(unit) && unit.factors.topic === topic);
    return { generated, references: referenceRows(data.units).map(row => ({ ...row, unit: row.unitFor(topic) })) };
  }, [data, topic]);

  if (failed) return <div className="container detector-comparison"><p>The comparison data could not be loaded.</p></div>;
  if (!texts) return <div className="container detector-comparison"><p>Loading…</p></div>;
  if (!texts.generated.length) return <div className="container detector-comparison"><p>No generated texts on this topic.</p></div>;

  const detectors = BAR_DETECTORS.filter(detector => selected.includes(detector.id));
  const models = modelsIn(texts.generated);
  const conditions = conditionsIn(texts.generated);
  const columns = [AVERAGE].concat(models);
  const toggle = id => setSelected(current => BAR_DETECTORS.map(detector => detector.id)
    .filter(item => (item === id ? !current.includes(id) : current.includes(item))));

  const unitCell = (unit, label, key) => {
    if (!unit) return <td key={key} className="detector-comparison__cell detector-comparison__cell--empty" />;
    const values = unitValues(unit, detectors);
    const enter = event => show(event, label, `${unit.words} words`, values);
    return (
      <td key={key} className="detector-comparison__cell">
        <Link
          className="detector-comparison__cell-link" to={`/detector_comparison/units/${unit.id}`} aria-label={`${label}: ${valuesLabel(values)}`}
          onMouseEnter={enter} onFocus={enter} onMouseLeave={hide} onBlur={hide}
        >
          <MiniBars values={values} />
        </Link>
      </td>
    );
  };

  const averageCell = (condition) => {
    const inCell = texts.generated.filter(unit => AVERAGE_MODELS.includes(unit.factors.model) && unit.condition === condition);
    if (!inCell.length) return <td key={AVERAGE} className="detector-comparison__cell detector-comparison__cell--empty" />;
    return (
      <td key={AVERAGE} className="detector-comparison__cell detector-comparison__cell--average">
        <AverageBars
          values={averageValues(inCell, detectors)} title={`${AVERAGE_ROW.label}, ${conditionLabel(condition)}`}
          count={inCell.length} show={show} hide={hide}
        />
      </td>
    );
  };

  return (
    <div className="container detector-comparison">
      <p><Link to={datasetPath('topics')}>← Texts on 16 topics</Link></p>
      <h1>{topic}<CreditsDagger /></h1>
      <p><a href={wikipediaUrl(topic)}>The Wikipedia article</a></p>

      <fieldset className="detector-comparison__filter detector-comparison__filter--inline">
        <legend>Detectors</legend>
        {BAR_DETECTORS.map(detector => (
          <label key={detector.id} htmlFor={`dc-topic-${detector.id}`} className="detector-comparison__filter-option">
            <input id={`dc-topic-${detector.id}`} type="checkbox" checked={selected.includes(detector.id)} onChange={() => toggle(detector.id)} />
            <svg width="10" height="10" aria-hidden="true"><rect width="10" height="10" rx="2" fill={detector.color} /></svg>
            {DETECTORS[detector.key]?.label || detector.key}
          </label>
        ))}
      </fieldset>
      <BarLegend detectors={detectors} />

      <div className="detector-comparison__tooltip-frame">
        <section>
          <h2>Reference texts</h2>
          <table className="detector-comparison__topic-grid detector-comparison__topic-grid--compact">
            <tbody>
              {texts.references.map(({ key, unit }) => {
                const reference = REFERENCE_ROWS.find(row => row.key === key);
                return (
                  <tr key={key}>
                    <th scope="row" title={reference.description}>
                      {unit ? <Link to={`/detector_comparison/units/${unit.id}`}>{reference.label}</Link> : reference.label}
                      {unit && reference.version && <> · <a href={unit.url}>revision</a></>}
                    </th>
                    {unitCell(unit, reference.label, 'reference')}
                  </tr>
                );
              })}
            </tbody>
          </table>
        </section>

        <section>
          <h2>Generated texts</h2>
          <div className="detector-comparison__scroll">
            <table className="detector-comparison__topic-grid">
              <thead>
                <tr>
                  <th scope="col" className="detector-comparison__corner">Prompt strategy</th>
                  {columns.map(column => (
                    <th
                      scope="col" key={column} title={column === AVERAGE ? AVERAGE_ROW.description : MODELS[column]?.detail}
                      className={`detector-comparison__topic-head${column === AVERAGE ? ' detector-comparison__topic-head--average' : ''}`}
                    >
                      <span>{column === AVERAGE ? AVERAGE_ROW.label : modelLabel(column)}</span>
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {conditions.map(condition => (
                  <tr key={condition}>
                    <th scope="row" title={CONDITIONS[condition]?.description}>{conditionLabel(condition)}</th>
                    {averageCell(condition)}
                    {models.map(model => unitCell(
                      texts.generated.find(unit => unit.factors.model === model && unit.condition === condition),
                      `${modelLabel(model)}, ${conditionLabel(condition)}`, model
                    ))}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>
        <Tooltip hover={hover} />
      </div>

      <AuthorshipNote generatedAt={data.generated_at} />
    </div>
  );
};

export default TopicPage;
