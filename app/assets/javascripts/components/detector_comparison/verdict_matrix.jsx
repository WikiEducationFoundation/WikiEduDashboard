/* eslint-disable i18next/no-literal-string */
// English-only admin research page: no i18n, by decision (see descriptions.js).
import React, { useMemo, useState } from 'react';
import PropTypes from 'prop-types';
import { Link } from 'react-router-dom';
import { CONDITIONS, DETECTORS, MATRIX_HELP, MODEL_GROUPS, MODELS } from './descriptions';
import {
  conditionsIn, detectorsIn, isAgpedia, isGenerated, isHuman, modelsIn, percent, shade, tally,
  topicOfPair, topicsIn, verdictFor
} from './data';
import VerdictChip from './verdict_chip';

const modelLabel = model => MODELS[model]?.label || model;
const conditionLabel = condition => CONDITIONS[condition]?.label || condition;

// The units for one topic that are not generated texts: the student text and any Agpedia articles.
const TopicReferences = ({ units, topic, detector }) => {
  const human = units.find(unit => isHuman(unit) && topicOfPair(units, unit.id) === topic);
  const agpedia = units.filter(unit => isAgpedia(unit) && unit.factors.topic === topic);
  const references = [
    human && { unit: human, label: 'Student text (pre-ChatGPT)' },
    ...agpedia.map(unit => ({ unit, label: `Agpedia article${unit.factors.excerpt === 'lead' ? ', lead' : ''}` })),
  ].filter(Boolean);
  if (!references.length) return null;
  return (
    <ul className="detector-comparison__references">
      {references.map(({ unit, label }) => (
        <li key={unit.id}>
          <Link to={`/detector_comparison/units/${unit.id}`}>{label}</Link>{' '}
          <VerdictChip verdict={verdictFor(unit, detector)} showScore />
        </li>
      ))}
    </ul>
  );
};

TopicReferences.propTypes = {
  units: PropTypes.array.isRequired,
  topic: PropTypes.string.isRequired,
  detector: PropTypes.string.isRequired,
};

const CellUnits = ({ cellUnits, detectors, title }) => (
  <div className="detector-comparison__cell-units">
    <h3>{title}</h3>
    <div className="detector-comparison__scroll">
      <table className="table table--hoverable">
        <thead>
          <tr>
            <th scope="col">Topic</th>
            <th scope="col">Words</th>
            {detectors.map(key => <th scope="col" key={key}>{DETECTORS[key]?.short || key}</th>)}
          </tr>
        </thead>
        <tbody>
          {cellUnits.map(unit => (
            <tr key={unit.id}>
              <td><Link to={`/detector_comparison/units/${unit.id}`}>{unit.factors.topic}</Link></td>
              <td>{unit.words}</td>
              {detectors.map(key => <td key={key}><VerdictChip verdict={verdictFor(unit, key)} showScore /></td>)}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  </div>
);

CellUnits.propTypes = {
  cellUnits: PropTypes.array.isRequired,
  detectors: PropTypes.array.isRequired,
  title: PropTypes.string.isRequired,
};

// Generated texts as a grid of models by conditions. Each cell counts the
// texts the selected detector flagged; with a topic chosen, each cell is one
// text. initialTopic fixes the grid to one topic, as on a unit's page.
const VerdictMatrix = ({ units, initialTopic = '', currentUnitId = null }) => {
  const generated = useMemo(() => units.filter(isGenerated), [units]);
  const detectors = useMemo(() => detectorsIn(generated), [generated]);
  const [detector, setDetector] = useState('Pangram 4');
  const [topic, setTopic] = useState(initialTopic);
  const [selected, setSelected] = useState(null);

  const visible = topic ? generated.filter(unit => unit.factors.topic === topic) : generated;
  const conditions = conditionsIn(generated);
  const models = modelsIn(generated);
  const groups = MODEL_GROUPS.concat([{ key: 'other', label: 'Other models' }]).map(group => ({
    ...group,
    models: models.filter(model => (MODELS[model]?.group || 'other') === group.key),
  })).filter(group => group.models.length);
  const cellUnits = (model, condition) => visible.filter(unit => unit.factors.model === model && unit.condition === condition);

  const renderCell = (model, condition) => {
    const inCell = cellUnits(model, condition);
    if (!inCell.length) return <td key={condition} className="detector-comparison__cell detector-comparison__cell--empty" />;
    if (topic) {
      const unit = inCell[0];
      const current = unit.id === currentUnitId;
      return (
        <td key={condition} className={`detector-comparison__cell${current ? ' detector-comparison__cell--current' : ''}`}>
          {current ? <span>This text</span> : <Link to={`/detector_comparison/units/${unit.id}`}>{unit.words} words</Link>}
          <br />
          <VerdictChip verdict={verdictFor(unit, detector)} showScore />
        </td>
      );
    }
    const { k, n } = tally(inCell, detector);
    const isSelected = selected?.model === model && selected?.condition === condition;
    return (
      <td key={condition} className="detector-comparison__cell" style={n ? shade(k / n) : undefined}>
        <button
          type="button"
          className="detector-comparison__cell-button"
          aria-pressed={isSelected}
          onClick={() => setSelected(isSelected ? null : { model, condition })}
        >
          <span className="detector-comparison__cell-rate">{percent(k, n)}</span>
          <span className="detector-comparison__cell-count">{k}/{n}</span>
        </button>
      </td>
    );
  };

  return (
    <div className="detector-comparison__matrix">
      <div className="detector-comparison__controls">
        <label htmlFor="detector-comparison-detector">
          Detector{' '}
          <select id="detector-comparison-detector" value={detector} onChange={event => setDetector(event.target.value)}>
            {detectors.map(key => <option key={key} value={key}>{DETECTORS[key]?.label || key}</option>)}
          </select>
        </label>
        {!initialTopic && (
          <label htmlFor="detector-comparison-topic">
            Topic{' '}
            <select id="detector-comparison-topic" value={topic} onChange={(event) => { setTopic(event.target.value); setSelected(null); }}>
              <option value="">All topics</option>
              {topicsIn(generated).map(name => <option key={name} value={name}>{name}</option>)}
            </select>
          </label>
        )}
      </div>
      <p className="detector-comparison__help">{DETECTORS[detector]?.description}</p>
      {!initialTopic && <p className="detector-comparison__help">{MATRIX_HELP}</p>}
      {topic && <TopicReferences units={units} topic={topic} detector={detector} />}
      <div className="detector-comparison__scroll">
        <table className="table detector-comparison__grid">
          <thead>
            <tr>
              <th scope="col">Model</th>
              {conditions.map(condition => (
                <th scope="col" key={condition} title={CONDITIONS[condition]?.description}>{conditionLabel(condition)}</th>
              ))}
            </tr>
          </thead>
          {groups.map(group => (
            <tbody key={group.key}>
              <tr className="detector-comparison__group-row">
                <th scope="colgroup" colSpan={conditions.length + 1}>{group.label}</th>
              </tr>
              {group.models.map(model => (
                <tr key={model}>
                  <th scope="row" title={MODELS[model]?.detail}>{modelLabel(model)}</th>
                  {conditions.map(condition => renderCell(model, condition))}
                </tr>
              ))}
            </tbody>
          ))}
        </table>
      </div>
      {selected && !topic && (
        <CellUnits
          cellUnits={cellUnits(selected.model, selected.condition)}
          detectors={detectors}
          title={`${modelLabel(selected.model)}, ${conditionLabel(selected.condition)}`}
        />
      )}
    </div>
  );
};

VerdictMatrix.propTypes = {
  units: PropTypes.array.isRequired,
  initialTopic: PropTypes.string,
  currentUnitId: PropTypes.number,
};

export default VerdictMatrix;
