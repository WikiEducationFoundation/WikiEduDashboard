import React from 'react';
const CoursesTaughtGraph = React.createClass({
  propTypes: {
    statsData: React.PropTypes.array,
    graphWidth: React.PropTypes.number,
    graphHeight: React.PropTypes.number
  },

  renderGraph() {
    const vegaSpec = {
      width: this.props.graphWidth,
      height: this.props.graphHeight,
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
              data: 'courses_count',
              field: 'course_start',
              sort: { field: 'date', op: 'min' }
            },
              {
                data: 'courses_count',
                field: 'course_end',
                sort: { field: 'date', op: 'min' }
              }
            ]
          },
          rangeMin: 0,
          rangeMax: this.props.graphWidth,
          round: true
        },
        {
          name: 'y',
          type: 'linear',
          domain: [0, 50, 0, 50],
          rangeMin: this.props.graphHeight,
          rangeMax: 0,
          round: true,
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
          ticks: 10,
          title: 'Date',
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
          format: 's',
          grid: true,
          layer: 'back',
          offset: 10,
          title: "Courses Taught"
        }
      ],
      // ///////////////
      // Data Sources //
      // ///////////////
      data: [
        {
          name: 'courses_count',
          values: this.props.statsData,
          format: { type: 'json', parse: { course_start: 'date', course_end: 'date' } },
          transform: [{
            type: 'filter',
            test: 'datum.course_start !== null && !isNaN(datum.course_start)'
          }
          ]
        }
      ],
      // //////////////
      // Mark layers //
      // //////////////
      marks: [
        {
          name: 'area_marks',
          type: 'area',
          from: {
            data: 'courses_count',
            transform: [{ type: 'sort', by: '-date' }]
          },
          properties: { enter: {
            orient: { value: 'vertical' },
            x: { scale: 'x', field: 'course_end' },
            y: { scale: 'y', value: 10 },
            y2: { scale: 'y', value: 0 },
            fill: { value: '#676EB4' },
            opacity: { value: 0.7 },
            interpolate: { value: 'step-before' }
          } }
        }
      ]
    };
    const embedSpec = {
      mode: 'vega', // instruct Vega-Embed to use vega compiler.
      spec: vegaSpec,
      actions: false
    };
    // emded the visualization in the container with id vega-graph-article_id
    vg.embed('#CoursesTaughtGraph', embedSpec); // Callback receiving View instance and parsed Vega spec
  },

  render() {
    this.renderGraph();
    console.log('courses count');
    console.log(this.props.statsData);
    return (
      <div>
        <h5>CoursesTaughtGraph </h5>
        <div id= "CoursesTaughtGraph" />
      </div>
    );
  }
});
export default CoursesTaughtGraph;
