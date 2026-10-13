/* eslint-disable i18next/no-literal-string */
// English-only admin research page: no i18n, by decision (see descriptions.js).
import React, { useState } from 'react';
import PropTypes from 'prop-types';
import { DETECTORS } from './descriptions';
import { formatScore, verdictFor } from './data';

const PLOT_HEIGHT = 40;
const BAR_WIDTH = 10;
const BAR_GAP = 3;

const hasScore = value => value.score !== null && value.score !== undefined;

// Each detector's value for a cell: one text's score and verdict, or the mean over several texts.
export const unitValues = (unit, detectors) => detectors.map((detector) => {
  const verdict = verdictFor(unit, detector.key);
  return { ...detector, score: verdict?.score, flagged: verdict?.flagged, label: verdict?.label };
});

export const averageValues = (units, detectors) => detectors.map((detector) => {
  const verdicts = units.map(unit => verdictFor(unit, detector.key)).filter(verdict => verdict && hasScore(verdict));
  const mean = verdicts.length ? verdicts.reduce((sum, verdict) => sum + verdict.score, 0) / verdicts.length : null;
  return { ...detector, score: mean, flagged: true, k: verdicts.filter(verdict => verdict.flagged).length, n: verdicts.length };
});

// One bar per detector: height is the score; solid when the verdict found AI (and for averages),
// faded when not. An unscored detector leaves its slot empty; a score of 0 still shows a hairline.
// The drawing stretches to the cell's width (preserveAspectRatio none), so bars widen with the grid.
export const MiniBars = ({ values }) => {
  const width = Math.max(1, (values.length * (BAR_WIDTH + BAR_GAP)) - BAR_GAP);
  return (
    <svg className="detector-comparison__bars" viewBox={`0 0 ${width} ${PLOT_HEIGHT}`} preserveAspectRatio="none" aria-hidden="true">
      <rect x="0" y="0" width={width} height={PLOT_HEIGHT} className="detector-comparison__bars-track" />
      {values.map((value, index) => {
        if (!hasScore(value)) return null;
        const height = Math.max(1, Math.round(value.score * PLOT_HEIGHT));
        return (
          <rect
            key={value.key} x={index * (BAR_WIDTH + BAR_GAP)} y={PLOT_HEIGHT - height} width={BAR_WIDTH} height={height}
            rx="1" fill={value.color} fillOpacity={value.flagged ? 1 : 0.4}
          />
        );
      })}
    </svg>
  );
};

MiniBars.propTypes = { values: PropTypes.array.isRequired };

// What a bar shows, in words: the score and verdict, or the mean and how many texts were flagged.
const valueText = (value, separator = ' · ') => {
  if (!hasScore(value)) return 'not scored';
  return value.n !== undefined
    ? `mean ${formatScore(value.score)}${separator}${value.k} of ${value.n} flagged`
    : `${formatScore(value.score)}${separator}${value.label || '?'}`;
};

// A cell's bars for screen readers, which can't see whether a bar is solid or faded.
export const valuesLabel = values => values.map(value => `${DETECTORS[value.key]?.short || value.key} ${valueText(value, ', ')}`).join('; ');

export const BarLegend = ({ detectors }) => (
  <div className="detector-comparison__legend">
    {detectors.map(({ key, color }) => (
      <span key={key} className="detector-comparison__legend-item">
        <svg width="12" height="12" aria-hidden="true"><rect width="12" height="12" rx="2" fill={color} /></svg>
        {DETECTORS[key]?.label || key}
      </span>
    ))}
    <span className="detector-comparison__legend-note">
      Bar height: the detector&apos;s whole-text AI score, 0 to 1. Solid: its verdict found AI. Faded: it called the text human. No bar: not scored.
      Averages are always solid; hover over or focus on one to see how many texts each detector flagged.
    </span>
  </div>
);

BarLegend.propTypes = { detectors: PropTypes.array.isRequired };

export const Tooltip = ({ hover }) => {
  if (!hover) return null;
  return (
    <div className="detector-comparison__tooltip" style={{ left: hover.x, top: hover.y }} role="presentation">
      <div className="detector-comparison__tooltip-title">{hover.title}</div>
      <div className="detector-comparison__tooltip-meta">{hover.meta}</div>
      {hover.values.map(value => (
        <div key={value.key} className="detector-comparison__tooltip-row">
          <svg width="10" height="10" aria-hidden="true"><rect width="10" height="10" rx="2" fill={value.color} /></svg>
          <span>{DETECTORS[value.key]?.short || value.key}</span>
          <span>{valueText(value)}</span>
        </div>
      ))}
    </div>
  );
};

Tooltip.propTypes = { hover: PropTypes.object };

// Positions the tooltip beside a cell, relative to the nearest .detector-comparison__tooltip-frame.
export const useCellTooltip = () => {
  const [hover, setHover] = useState(null);
  const show = (event, title, meta, values) => {
    const cell = event.currentTarget.getBoundingClientRect();
    const box = event.currentTarget.closest('.detector-comparison__tooltip-frame').getBoundingClientRect();
    setHover({ title, meta, values, x: cell.right - box.left + 6, y: cell.top - box.top });
  };
  return { hover, show, hide: () => setHover(null) };
};

// A cell averaged over several texts. Unlike a single text's cell it is not a link, so it takes
// focus itself to show its tooltip, and its label carries what the bars and the tooltip show.
export const AverageBars = ({ values, title, place, count, show, hide }) => {
  const texts = `${count} texts`;
  const enter = event => show(event, title, [place, texts].filter(Boolean).join(' · '), values);
  return (
    <span
      className="detector-comparison__cell-link" role="img"
      // eslint-disable-next-line jsx-a11y/no-noninteractive-tabindex -- focus shows the tooltip, as on single-text cells
      tabIndex={0}
      aria-label={`${[title, place, texts].filter(Boolean).join(', ')}: ${valuesLabel(values)}`}
      onMouseEnter={enter} onFocus={enter} onMouseLeave={hide} onBlur={hide}
    >
      <MiniBars values={values} />
    </span>
  );
};

AverageBars.propTypes = {
  values: PropTypes.array.isRequired,
  title: PropTypes.string.isRequired,
  place: PropTypes.string,
  count: PropTypes.number.isRequired,
  show: PropTypes.func.isRequired,
  hide: PropTypes.func.isRequired,
};
