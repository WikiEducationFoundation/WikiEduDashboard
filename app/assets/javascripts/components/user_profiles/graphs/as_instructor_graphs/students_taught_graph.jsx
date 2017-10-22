import React from 'react';
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
          fields: [{
            data: 'courses_data',
            field: 'created_at=',
            sort: { field: 'date', op: 'min' }
          }
          ]
        },
        rangeMin: 0,
        rangeMax: graphWidth,
        round: true
      },
      {
        name: 'y',
        type: 'linear',
        domain: {
          data: 'courses_data',
          field: 'index'
        },
        rangeMin: graphHeight,
        rangeMax: 0,
        nice: true,
        zero: true
      }
    ],
    axes: [
      {
        type: 'x',
        scale: 'x',
        grid: true,
        layer: 'back',
        title: 'Date',
        ticks: 10,
        properties: {
          labels: {
            text: { template: '{{datum["data"] | time:\'%b\'%d/%y\'}}' },
            angle: { value: 0 },
            fontSize: { value: 9 }
          }
        }
      },
      {
        type: 'y',
        scale: 'y',
        title: I18n.t(`${courseStringPrefix}.students_taught`),
        grid: true,
        layer: 'back',
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
          data: 'courses_data',
          transform: [{ type: 'sort', by: '-date' }]
        },
        properties: { enter: {
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
          data: 'courses_data',
          transform: [{ type: 'sort', by: '-date' }]
        },
        properties: { enter: {
          x: { scale: 'x', field: 'created_at=' },
          y: { scale: 'y', field: 'index' },
          stroke: { value: "#575d99" },
          strokeWidth: { value: 1 }
        }
        }
      }
    ]
  };
  const embedSpec = {
    mode: 'vega', // instruct Vega-Embed to use vega compiler.
    spec: vegaSpec,
    actions: false
  };
  // emded the visualization in the container with id vega-graph-article_id
  vg.embed('#StudentsTaughGraph', embedSpec); // Callback receiving View instance and parsed Vega spec
};

const StudentsTaughtGraph = ({ statsData, graphWidth, graphHeight, courseStringPrefix }) => {
  renderGraph(statsData, graphWidth, graphHeight, courseStringPrefix);
  return (
    <div id ="stats_graph">
      <h5> {I18n.t(`${courseStringPrefix}.students_taught`)} </h5>
      <div id= "StudentsTaughGraph" />
    </div>
  );
};
StudentsTaughtGraph.propTypes = {
  statsData: PropTypes.array,
  graphWidth: PropTypes.number,
  graphHeight: PropTypes.number,
  courseStringPrefix: PropTypes.string
};

export default StudentsTaughtGraph;
