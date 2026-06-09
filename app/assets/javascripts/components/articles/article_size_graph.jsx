/* global vegaEmbed */
import React, { useEffect } from 'react';
import PropTypes from 'prop-types';

// Visualizes the total size of the article (in bytes) at each revision over the
// course period. The size trajectory is a neutral line/area; each edit is a
// point colored by editor (color is precomputed by the parent), so the legend
// and coloring are shared with the Structural Completeness graph.
const LINE_COLOR = '#999999';
const POINT_STROKE = '#666666';

const ArticleSizeGraph = (props) => {
  useEffect(() => {
    renderGraph();
  }, []);

  // Anchor the x-axis to the full course period when available, so each edit
  // shows where it falls in the course timeline.
  const courseStartMs = Date.parse(props.courseStart);
  const courseEndMs = Date.parse(props.courseEnd);
  const hasCourseRange = !isNaN(courseStartMs) && !isNaN(courseEndMs);
  const xDomain = hasCourseRange
    ? [courseStartMs, courseEndMs]
    : { data: 'article_size', field: 'date' };

  const renderGraph = () => {
    const vegaSpec = {
      width: props.graphWidth,
      height: props.graphHeight,
      padding: 5,
      // graphWidth is the total width the popover can give us; fit-x shrinks the
      // plotting area so the y-axis lays out inside it instead of overflowing.
      autosize: { type: 'fit-x', contains: 'padding', resize: true },
      data: [
        {
          name: 'article_size',
          values: props.articleData,
          format: { type: 'json', parse: { date: 'date', characters: 'number' } },
          transform: [
            {
              type: 'filter',
              expr: 'datum.date !== null && !isNaN(datum.date) && datum.characters !== null && !isNaN(datum.characters)'
            },
            { type: 'collect', sort: { field: 'date' } }
          ]
        },
        {
          // Points exclude the baseline (rendered only as the line/area) and are
          // ordered so 'other' editors draw first and participant edits draw on
          // top, keeping the edits we care about visible above dense clusters.
          name: 'edit_points',
          source: 'article_size',
          transform: [
            { type: 'filter', expr: '!datum.baseline' },
            { type: 'collect', sort: { field: 'participant' } }
          ]
        }
      ],
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
          domain: { data: 'article_size', field: 'characters' },
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
          title: I18n.t('articles.article_size')
        }
      ],
      marks: [
        {
          type: 'area',
          from: { data: 'article_size' },
          encode: {
            update: {
              x: { scale: 'x', field: 'date' },
              y: { scale: 'y', field: 'characters' },
              y2: { scale: 'y', value: 0 },
              fill: { value: LINE_COLOR },
              fillOpacity: { value: 0.1 }
            }
          }
        },
        {
          type: 'line',
          from: { data: 'article_size' },
          encode: {
            update: {
              x: { scale: 'x', field: 'date' },
              y: { scale: 'y', field: 'characters' },
              stroke: { value: LINE_COLOR },
              strokeWidth: { value: 1.5 }
            }
          }
        },
        {
          type: 'symbol',
          from: { data: 'edit_points' },
          encode: {
            update: {
              x: { scale: 'x', field: 'date' },
              y: { scale: 'y', field: 'characters' },
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
                  + `'${I18n.t('articles.article_size')}': format(datum.characters, ','), `
                  + `'${I18n.t('users.username')}': datum.username}`
              }
            }
          }
        }
      ]
    };

    vegaEmbed(`#${props.graphid}`, vegaSpec, { defaultStyle: true, tooltip: true, actions: { source: false } })
      .then((result) => {
        // Clicking a point opens that revision's diff on the wiki.
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

ArticleSizeGraph.propTypes = {
  graphid: PropTypes.string,
  graphWidth: PropTypes.number,
  graphHeight: PropTypes.number,
  articleData: PropTypes.array,
  courseStart: PropTypes.string,
  courseEnd: PropTypes.string,
  wikiUrl: PropTypes.string
};

export default ArticleSizeGraph;
