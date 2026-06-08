/* global vegaEmbed */
import React, { useEffect } from 'react';
import PropTypes from 'prop-types';

// Plots the wp10 (Structural Completeness) score at each revision over the
// course period. The quality trend is a neutral step area; each edit is a
// point colored by editor (color precomputed by the parent), matching the
// Article Size graph and its shared legend.
const AREA_COLOR = '#999999';
const POINT_STROKE = '#666666';

const Wp10Graph = (props) => {
  useEffect(() => {
    renderGraph();
  }, []);

  // Anchor the x-axis to the full course period when available.
  const courseStartMs = Date.parse(props.courseStart);
  const courseEndMs = Date.parse(props.courseEnd);
  const hasCourseRange = !isNaN(courseStartMs) && !isNaN(courseEndMs);
  const xDomain = hasCourseRange
    ? [courseStartMs, courseEndMs]
    : { data: 'wp10_scores', field: 'date', sort: { field: 'date', op: 'min' } };

  const renderGraph = () => {
    const vegaSpec = {
      width: props.graphWidth,
      height: props.graphHeight,
      padding: 5,
      // graphWidth is the total width the popover can give us; fit-x shrinks the
      // plotting area so the y-axis lays out inside it instead of overflowing.
      autosize: { type: 'fit-x', contains: 'padding', resize: true },
      scales: [
        {
          name: 'x',
          type: 'time',
          domain: xDomain,
          // fit-x reduces the plot width to make room for the y-axis; follow the
          // resulting `width` signal rather than the requested total graphWidth.
          range: [0, { signal: 'width' }],
          round: true
        },
        {
          name: 'y',
          type: 'linear',
          domain: [0, 100],
          range: [props.graphHeight, 0],
          round: true,
          nice: true,
          zero: true
        }
      ],
      axes: [
        {
          orient: 'bottom',
          scale: 'x',
          grid: true,
          ticks: true,
          labelOverlap: true,
          labelFlush: true,
          title: 'Date'
        },
        {
          orient: 'left',
          scale: 'y',
          format: 's',
          grid: true,
          offset: 10,
          title: I18n.t('articles.wp10')
        }
      ],
      data: [
        {
          name: 'wp10_scores',
          values: props.articleData,
          format: { type: 'json', parse: { date: 'date', wp10: 'number' } },
          transform: [
            {
              type: 'filter',
              expr: 'datum.date !== null && !isNaN(datum.date) && datum.wp10 !== null && !isNaN(datum.wp10)'
            },
            { type: 'collect', sort: { field: 'date' } }
          ]
        },
        {
          // Points exclude the baseline (line/area only) and draw 'other'
          // editors first so participant edits stay visible on top.
          name: 'wp10_points',
          source: 'wp10_scores',
          transform: [
            { type: 'filter', expr: '!datum.baseline' },
            { type: 'collect', sort: { field: 'participant' } }
          ]
        }
      ],
      marks: [
        {
          type: 'area',
          from: { data: 'wp10_scores' },
          encode: {
            update: {
              orient: { value: 'vertical' },
              x: { scale: 'x', field: 'date' },
              y: { scale: 'y', field: 'wp10' },
              y2: { scale: 'y', value: 0 },
              fill: { value: AREA_COLOR },
              fillOpacity: { value: 0.12 },
              interpolate: { value: 'step-after' }
            }
          }
        },
        {
          type: 'symbol',
          from: { data: 'wp10_points' },
          encode: {
            update: {
              x: { scale: 'x', field: 'date' },
              y: { scale: 'y', field: 'wp10' },
              size: [
                { test: 'datum.participant', value: 110 },
                { value: 45 }
              ],
              shape: { value: 'circle' },
              fill: { field: 'color' },
              fillOpacity: { value: 0.95 },
              stroke: { value: POINT_STROKE },
              strokeWidth: { value: 1 },
              cursor: { value: 'pointer' },
              tooltip: {
                signal: `{'Date': timeFormat(datum.date, '%b %e, %Y'), `
                  + `'${I18n.t('articles.wp10')}': format(datum.wp10, '.0f'), `
                  + `'${I18n.t('users.username')}': datum.username}`
              }
            }
          }
        }
      ]
    };

    vegaEmbed(`#${props.graphid}`, vegaSpec, { defaultStyle: true, tooltip: true, actions: { source: false } })
      .then((result) => {
        result.view.addEventListener('click', (event, item) => {
          if (item?.mark?.marktype === 'symbol' && item.datum?.rev_id) {
            window.open(`${props.wikiUrl}/w/index.php?diff=${item.datum.rev_id}`, '_blank', 'noopener');
          }
        });
      })
      .catch(() => { /* graph failed to render; nothing to wire up */ });
  };

  return (
    <div>
      <div id={props.graphid} />
    </div>
  );
};

Wp10Graph.displayName = 'Wp10Graph';
Wp10Graph.propTypes = {
  graphid: PropTypes.string,
  graphWidth: PropTypes.number,
  graphHeight: PropTypes.number,
  articleData: PropTypes.array,
  courseStart: PropTypes.string,
  courseEnd: PropTypes.string,
  wikiUrl: PropTypes.string
};

export default Wp10Graph;
