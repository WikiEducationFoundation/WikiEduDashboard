/* eslint-disable i18next/no-literal-string */
// English-only admin research page: no i18n, by decision (see descriptions.js).
import React, { useMemo } from 'react';
import PropTypes from 'prop-types';
import { Link } from 'react-router-dom';
import {
  AVERAGE_LABEL, AVERAGE_MODELS, AVERAGE_ROW, CONDITIONS, DETECTORS, MODEL_GROUPS, MODELS, REFERENCE_ROWS
} from './descriptions';
import {
  BAR_DETECTORS, conditionsIn, formatScore, isGenerated, modelsIn, pairedIdsOf, referenceKey, topicOfPair, topicsIn, verdictFor
} from './data';
import { averageValues, BarLegend, MiniBars, Tooltip, unitValues, useCellTooltip, valuesLabel } from './bars';
import { useSelection } from './selection';

const AVERAGE = 'average';

export const modelLabel = model => (model === AVERAGE_ROW.key ? AVERAGE_ROW.label
  : REFERENCE_ROWS.find(row => row.key === model)?.label || MODELS[model]?.label || model);
export const conditionLabel = condition => CONDITIONS[condition]?.label || condition;
export const topicPath = topic => `/detector_comparison/topics/${encodeURIComponent(topic)}`;

// A row per kind of reference text (REFERENCE_ROWS), each finding its text on a topic.
export const referenceRows = (units) => {
  const pairedIds = pairedIdsOf(units.filter(isGenerated));
  const references = units.filter(unit => !isGenerated(unit));
  const topicOf = unit => unit.factors.topic || topicOfPair(units, unit.id);
  return REFERENCE_ROWS.map((reference) => {
    const inRow = references.filter(unit => referenceKey(unit, pairedIds) === reference.key);
    return { key: reference.key, model: reference.key, reference: true, unitFor: topic => inRow.find(unit => topicOf(unit) === topic) };
  });
};

const meanPangram = (units) => {
  const scores = units.map(unit => verdictFor(unit, 'Pangram 4')?.score).filter(score => score !== null && score !== undefined);
  return scores.length ? scores.reduce((sum, score) => sum + score, 0) / scores.length : null;
};

// Every row the data supports: the reference rows, an average row per strategy, then each model
// and strategy with texts. Topics are ordered by Pangram 4's mean on the averaged models' texts.
export const buildRows = (units) => {
  const generated = units.filter(isGenerated);
  const topics = topicsIn(generated);
  const rows = referenceRows(units).map(row => ({ ...row, units: topics.map(row.unitFor).filter(Boolean) }));
  const conditions = conditionsIn(generated);
  const averaged = generated.filter(unit => AVERAGE_MODELS.includes(unit.factors.model));
  conditions.forEach((condition) => {
    const inRow = averaged.filter(unit => unit.condition === condition);
    if (!inRow.length) return;
    rows.push({
      key: `${AVERAGE_ROW.key}/${condition}`, model: AVERAGE_ROW.key, condition, average: true, units: inRow,
      unitsFor: topic => inRow.filter(unit => unit.factors.topic === topic)
    });
  });
  modelsIn(generated).forEach((model) => {
    conditions.forEach((condition) => {
      const inRow = generated.filter(unit => unit.factors.model === model && unit.condition === condition);
      if (!inRow.length) return;
      rows.push({ key: `${model}/${condition}`, model, condition, units: inRow, unitFor: topic => inRow.find(unit => unit.factors.topic === topic) });
    });
  });
  const pangramMeans = Object.fromEntries(topics.map(topic => [topic, meanPangram(averaged.filter(unit => unit.factors.topic === topic))]));
  const columnOrder = [...topics].sort((a, b) => (pangramMeans[b] ?? -1) - (pangramMeans[a] ?? -1));
  return { rows, topics, columnOrder, pangramMeans, models: modelsIn(generated), conditions };
};

const CheckboxGroup = ({ legend, name, items, selected, onToggle, onSet }) => (
  <fieldset className="detector-comparison__filter">
    <legend>{legend}</legend>
    <div className="detector-comparison__filter-actions">
      <button type="button" onClick={() => onSet(items.filter(item => !item.heading).map(item => item.value))}>All</button>
      <button type="button" onClick={() => onSet([])}>None</button>
    </div>
    {items.map((item) => {
      if (item.heading) return <div key={`h-${item.heading}`} className="detector-comparison__filter-heading">{item.heading}</div>;
      const id = `dc-${name}-${item.value}`.replace(/[^\w-]/g, '_');
      return (
        <label key={item.value} htmlFor={id} className="detector-comparison__filter-option" title={item.title}>
          <input id={id} type="checkbox" checked={selected.includes(item.value)} onChange={() => onToggle(item.value)} />
          {item.swatch && <svg width="10" height="10" aria-hidden="true"><rect width="10" height="10" rx="2" fill={item.swatch} /></svg>}
          {item.label}
        </label>
      );
    })}
  </fieldset>
);

CheckboxGroup.propTypes = {
  legend: PropTypes.string.isRequired,
  name: PropTypes.string.isRequired,
  items: PropTypes.array.isRequired,
  selected: PropTypes.array.isRequired,
  onToggle: PropTypes.func.isRequired,
  onSet: PropTypes.func.isRequired,
};

const AGPEDIA_ROW = 'reference:agpedia';

// Rows grouped by model (strategies inside, simple to complex) or by strategy (models inside),
// with the averages leading. The Wikipedia and student references come first; the Agpedia
// article, written through an agent with tools, is the far end of the generated texts, so it
// comes last.
const groupRows = (rows, groupBy) => {
  const groups = [];
  const reference = rows.filter(row => row.reference && row.model !== AGPEDIA_ROW);
  const agpedia = rows.filter(row => row.model === AGPEDIA_ROW);
  if (reference.length) {
    groups.push({ key: 'reference', label: 'Reference texts', rows: reference.map(row => ({ key: row.key, label: modelLabel(row.model), row })) });
  }
  const generated = rows.filter(row => !row.reference).sort((a, b) => Number(Boolean(b.average)) - Number(Boolean(a.average)));
  const keyOf = row => (groupBy === 'strategy' ? row.condition : row.model);
  [...new Set(generated.map(keyOf))].forEach((key) => {
    const inGroup = generated.filter(row => keyOf(row) === key);
    groups.push(groupBy === 'strategy'
      ? { key, label: conditionLabel(key), detail: CONDITIONS[key]?.description, rows: inGroup.map(row => ({ key: row.key, label: modelLabel(row.model), title: MODELS[row.model]?.detail, row })) }
      : { key, label: modelLabel(key), detail: key === AVERAGE_ROW.key ? AVERAGE_ROW.description : MODELS[key]?.detail, rows: inGroup.map(row => ({ key: row.key, label: conditionLabel(row.condition), title: CONDITIONS[row.condition]?.description, row })) });
  });
  if (agpedia.length) {
    groups.push({
      key: 'agpedia', label: 'Agentic writing', detail: REFERENCE_ROWS.find(row => row.key === AGPEDIA_ROW)?.description,
      rows: agpedia.map(row => ({ key: row.key, label: modelLabel(row.model), row }))
    });
  }
  return groups;
};

const Grid = ({ rowGroups, columns, detectors, columnTitles }) => {
  const { hover, show, hide } = useCellTooltip();

  const averageCell = (column, label, meta, inCell) => {
    if (!inCell.length) return <td key={column} className="detector-comparison__cell detector-comparison__cell--empty" />;
    const values = averageValues(inCell, detectors);
    return (
      <td key={column} className={`detector-comparison__cell${column === AVERAGE ? ' detector-comparison__cell--average' : ''}`}>
        <span className="detector-comparison__cell-link" onMouseEnter={event => show(event, label, meta, values)} onMouseLeave={hide}>
          <MiniBars values={values} />
        </span>
      </td>
    );
  };

  const renderCell = (row, column) => {
    const label = row.reference ? modelLabel(row.model) : `${modelLabel(row.model)}, ${conditionLabel(row.condition)}`;
    if (column === AVERAGE) return averageCell(column, label, `${AVERAGE_LABEL} · ${row.units.length} texts`, row.units);
    if (row.average) {
      const inCell = row.unitsFor(column);
      return averageCell(column, label, `${column} · ${inCell.length} texts`, inCell);
    }
    const unit = row.unitFor(column);
    if (!unit) return <td key={column} className="detector-comparison__cell detector-comparison__cell--empty" />;
    const values = unitValues(unit, detectors);
    const enter = event => show(event, label, `${column} · ${unit.words} words`, values);
    return (
      <td key={column} className="detector-comparison__cell">
        <Link
          className="detector-comparison__cell-link" to={`/detector_comparison/units/${unit.id}`}
          aria-label={`${label}, ${column}: ${valuesLabel(values)}`}
          onMouseEnter={enter} onFocus={enter} onMouseLeave={hide} onBlur={hide}
        >
          <MiniBars values={values} />
        </Link>
      </td>
    );
  };

  return (
    <div className="detector-comparison__tooltip-frame">
      <div className="detector-comparison__scroll">
        <table className="detector-comparison__topic-grid">
          <thead>
            <tr>
              <th scope="col" className="detector-comparison__corner" />
              {columns.map(column => (
                <th scope="col" key={column} title={columnTitles[column]} className={`detector-comparison__topic-head${column === AVERAGE ? ' detector-comparison__topic-head--average' : ''}`}>
                  {column === AVERAGE ? <span>{AVERAGE_LABEL}</span> : <Link to={topicPath(column)}><span>{column}</span></Link>}
                </th>
              ))}
            </tr>
          </thead>
          {rowGroups.map(group => (
            <tbody key={group.key}>
              <tr className="detector-comparison__group-row">
                <th scope="colgroup" colSpan={columns.length + 1}>
                  {group.label}{group.detail && <span className="detector-comparison__group-detail"> · {group.detail}</span>}
                </th>
              </tr>
              {group.rows.map(row => (
                <tr key={row.key}>
                  <th scope="row" title={row.title}>{row.label}</th>
                  {columns.map(column => renderCell(row.row, column))}
                </tr>
              ))}
            </tbody>
          ))}
        </table>
      </div>
      <Tooltip hover={hover} />
    </div>
  );
};

Grid.propTypes = {
  rowGroups: PropTypes.array.isRequired,
  columns: PropTypes.array.isRequired,
  detectors: PropTypes.array.isRequired,
  columnTitles: PropTypes.object.isRequired,
};

// The texts on each topic as a grid: a column per topic and a row per model or average and
// strategy, with the selectors in a collapsed panel above it.
const TopicMatrix = ({ units }) => {
  const { rows, topics, columnOrder, pangramMeans, models, conditions } = useMemo(() => buildRows(units), [units]);
  const options = {
    models: REFERENCE_ROWS.map(row => row.key).concat([AVERAGE_ROW.key], models),
    strategies: conditions,
    detectors: BAR_DETECTORS.map(detector => detector.id),
    topics: [AVERAGE].concat(topics),
  };
  const { selection, toggle, update, setGroupBy } = useSelection(options);

  const detectors = BAR_DETECTORS.filter(detector => selection.detectors.includes(detector.id));
  const columns = [AVERAGE].concat(columnOrder).filter(topic => selection.topics.includes(topic));
  const columnTitles = Object.fromEntries(columnOrder.map(topic => [topic, `Pangram 4 mean on the current models' texts: ${formatScore(pangramMeans[topic])}. Select for every text on this topic.`]));
  // Rows follow the order of the selected strategies, so a curated view can put related ones together.
  const strategyRank = row => (row.reference ? -1 : selection.strategies.indexOf(row.condition));
  const visibleRows = rows
    .filter(row => selection.models.includes(row.model) && (row.reference || selection.strategies.includes(row.condition)))
    .sort((a, b) => strategyRank(a) - strategyRank(b));
  const modelItems = [{ heading: 'Reference texts' }].concat(
    REFERENCE_ROWS.map(row => ({ value: row.key, label: row.label, title: row.description })),
    [{ heading: 'Averages' }, { value: AVERAGE_ROW.key, label: AVERAGE_ROW.label, title: AVERAGE_ROW.description }],
    MODEL_GROUPS.flatMap(group => [{ heading: group.label }].concat(
      models.filter(model => (MODELS[model]?.group || 'current') === group.key).map(model => ({ value: model, label: modelLabel(model), title: MODELS[model]?.detail }))
    ))
  );

  return (
    <div className="detector-comparison__topic-matrix">
      <details className="detector-comparison__filter-panel">
        <summary>Change what the table shows</summary>
        <div className="detector-comparison__filters">
          <CheckboxGroup legend="Models" name="models" items={modelItems} selected={selection.models} onToggle={value => toggle('models', value)} onSet={values => update('models', values)} />
          <CheckboxGroup
            legend="Prompt strategies" name="strategies" selected={selection.strategies}
            items={conditions.map(condition => ({ value: condition, label: conditionLabel(condition), title: CONDITIONS[condition]?.description }))}
            onToggle={value => toggle('strategies', value)} onSet={values => update('strategies', values)}
          />
          <CheckboxGroup
            legend="Detectors" name="detectors" selected={selection.detectors}
            items={BAR_DETECTORS.map(detector => ({ value: detector.id, label: DETECTORS[detector.key]?.label || detector.key, swatch: detector.color }))}
            onToggle={value => toggle('detectors', value)} onSet={values => update('detectors', values)}
          />
          <CheckboxGroup
            legend="Topics" name="topics" selected={selection.topics}
            items={options.topics.map(topic => ({ value: topic, label: topic === AVERAGE ? AVERAGE_LABEL : topic }))}
            onToggle={value => toggle('topics', value)} onSet={values => update('topics', values)}
          />
          <fieldset className="detector-comparison__filter">
            <legend>Group rows by</legend>
            {[['model', 'Model'], ['strategy', 'Prompt strategy']].map(([value, label]) => (
              <label key={value} htmlFor={`dc-group-${value}`} className="detector-comparison__filter-option">
                <input id={`dc-group-${value}`} type="radio" name="dc-group" checked={selection.groupBy === value} onChange={() => setGroupBy(value)} />
                {label}
              </label>
            ))}
          </fieldset>
        </div>
      </details>
      <BarLegend detectors={detectors} />
      {detectors.length && columns.length && visibleRows.length
        ? <Grid rowGroups={groupRows(visibleRows, selection.groupBy)} columns={columns} detectors={detectors} columnTitles={columnTitles} />
        : <p className="detector-comparison__help">Select at least one model, prompt strategy, detector and topic.</p>}
    </div>
  );
};

TopicMatrix.propTypes = { units: PropTypes.array.isRequired };

export default TopicMatrix;
