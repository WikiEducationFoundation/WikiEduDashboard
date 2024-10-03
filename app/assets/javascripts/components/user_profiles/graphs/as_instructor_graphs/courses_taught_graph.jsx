/* eslint-disable react/jsx-indent */
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
          fields: ['course_start', 'course_end']
        },
        range: 'width',
        round: true
      },
      {
        name: 'y',
        type: 'band',
        domain: {
          data: 'courses_data',
          field: 'index'
        },
        range: 'height',
        round: true,
        nice: true,
        zero: true,
        reverse: true
      },
      {
        name: 'color',
        type: 'ordinal',
        range: [
          '#40AD90', '#545CB8', '#41AE5D', '#7A51B6', '#5CAF43', '#A94FB5', '#91B045', '#B44D8F', '#B19D47', '#B34B5B', '#B26C49'
        ]
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
        title: I18n.t(`${courseStringPrefix}.courses_taught`),
        grid: true,
        offset: 10,
        ticks: false,
        values: []
      }
    ],
    // ///////////////
    // Data Sources //
    // ///////////////
    data: [
      {
        name: 'courses_data',
        values: statsData,
        format: { type: 'json', parse: { course_start: 'date', course_end: 'date' } }
      }
    ],
    // //////////////
    // Mark layers //
    // //////////////
    marks: [
      {
        name: 'rect_marks',
        type: 'rect',
        from: {
          data: 'courses_data'
        },
        encode: { enter: {
          x: { scale: 'x', field: 'course_start' },
          x2: { scale: 'x', field: 'course_end' },
          y: { scale: 'y', field: 'index' },
          height: {
            value: 10,
            band: 1
          },
          fill: {
            scale: 'color', field: 'index'
          },
          tooltip: { field: 'course_title' }
        }
        }
      }
    ]
  };
  // emded the visualization in the container with id vega-graph-article_id\
  /* eslint no-undef:0 */ // This method is imported as <script> tag in _vega.html.haml
  vegaEmbed('#CoursesTaughtGraph', vegaSpec, { defaultStyle: true, actions: { source: false } });
};

const CoursesTaughtGraph = (props) => {
  useEffect(() => {
    renderGraph(props.statsData, props.graphWidth, props.graphHeight, props.courseStringPrefix);
  }, []);
  return (
      <div id="stats_graph">
        <h5> {I18n.t(`${props.courseStringPrefix}.courses_taught`)} </h5>
        <div id="CoursesTaughtGraph" />
      </div>
  );
};

CoursesTaughtGraph.displayName = 'CoursesTaughtGraph';
CoursesTaughtGraph.propTypes = {
  statsData: PropTypes.array,
  graphWidth: PropTypes.number,
  graphHeight: PropTypes.number,
  courseStringPrefix: PropTypes.string
};

export default CoursesTaughtGraph;
