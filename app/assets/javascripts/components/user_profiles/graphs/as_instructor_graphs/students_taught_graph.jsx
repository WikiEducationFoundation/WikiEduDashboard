import React, { useEffect } from 'react';
import PropTypes from 'prop-types';

const renderGraph = (statsData, graphWidth, graphHeight, courseStringPrefix) => {
  const vegaSpec = {
    width: graphWidth,
    height: graphHeight,
    padding: { top: 40, left: 70, right: 20, bottom: 35 },
    // //////////////////
    // Scales and Axes //
    // //////////////////
    scales: [
      {
        name: 'x',
        type: 'time',
        domain: {
          data: 'courses_data',
          field: 'created_at=',
          sort: { field: 'date', op: 'min' }
        },
        range: 'width',
        round: true
      },
      {
        name: 'y',
        type: 'linear',
        domain: {
          data: 'courses_data',
          field: 'index'
        },
        range: 'height',
        nice: true,
        zero: true
      }
    ],
    axes: [
      {
        orient: 'bottom',
        scale: 'x',
        grid: true,
        title: 'Date',
        ticks: true
      },
      {
        orient: 'left',
        scale: 'y',
        title: I18n.t(`${courseStringPrefix}.students_taught`),
        grid: true,
        offset: 10
      }
    ],
    // ///////////////
    // Data Sources //
    // ///////////////
    data: [
      {
        name: 'courses_data',
        values: statsData,
        format: { type: 'json', parse: { 'created_at=': 'date', index: 'number' } }
      }
    ],
    // //////////////
    // Mark layers //
    // //////////////
    marks: [
      {
        name: 'symbol_marks',
        type: 'symbol',
        from: {
          data: 'courses_data'
        },
        encode: { enter: {
          x: { scale: 'x', field: 'created_at=' },
          y: { scale: 'y', field: 'index', offset: -1 },
          size: { value: 60 },
          shape: { value: 'circle' },
          fill: { value: '#359178' },
          opacity: { value: 0.7 }
        }
        }
      },
      {
        type: 'line',
        from: {
          data: 'courses_data'
        },
        encode: { enter: {
          x: { scale: 'x', field: 'created_at=' },
          y: { scale: 'y', field: 'index' },
          stroke: { value: '#575d99' },
          strokeWidth: { value: 1 }
        }
        }
      }
    ]
  };
  // emded the visualization in the container with id vega-graph-article_id
  /* eslint no-undef:0 */ // This method is imported as <script> tag in _vega.html.haml
  vegaEmbed('#StudentsTaughGraph', vegaSpec, { defaultStyle: true, actions: { source: false } });
};

const StudentsTaughtGraph = (props) => {
  useEffect(() => {
    renderGraph(props.statsData, props.graphWidth, props.graphHeight, props.courseStringPrefix);
  }, []);
    return (
      <div id="stats_graph">
        <h5> {I18n.t(`${props.courseStringPrefix}.students_taught`)} </h5>
        <div id="StudentsTaughGraph" />
      </div>
    );
  };
StudentsTaughtGraph.displayName = 'StudentsTaughtGraph';
StudentsTaughtGraph.propTypes = {
  statsData: PropTypes.array,
  graphWidth: PropTypes.number,
  graphHeight: PropTypes.number,
  courseStringPrefix: PropTypes.string
};

export default StudentsTaughtGraph;
