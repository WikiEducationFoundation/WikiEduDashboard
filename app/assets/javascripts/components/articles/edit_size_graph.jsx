/* global vegaEmbed */
import React, { useEffect } from 'react';
import PropTypes from 'prop-types';

const EditSizeGraph = (props) => {
  useEffect(() => {
    renderGraph();
  }, []);

  const renderGraph = () => {
    const vegaSpec = {
      width: props.graphWidth,
      height: props.graphHeight,
      padding: 5,
      // //////////////////
      // Scales and Axes //
      // //////////////////
      scales: [
        {
          name: 'x',
          type: 'time',
          domain: {
            data: 'characters_edited',
            field: 'date',
            sort: { field: 'date', op: 'min' }
          },
          range: [0, props.graphWidth],
          round: true
        },
        {
          name: 'y',
          type: 'linear',
          domain: {
            data: 'characters_edited',
            field: 'characters'
          },
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
          title: 'Date'
        },
        {
          orient: 'left',
          scale: 'y',
          format: 's',
          grid: true,
          offset: 10,
          title: I18n.t('metrics.characters')
        }
      ],
      // ///////////////
      // Data Sources //
      // ///////////////
      data: [
        {
          name: 'characters_edited',
          values: props.articleData,
          format: { type: 'json', parse: { date: 'date', characters: 'number' } },
          transform: [{
            type: 'filter',
            expr: 'datum.date !== null && !isNaN(datum.date) && datum.characters!== null && !isNaN(datum.characters) && datum.characters !== 0'
          }
          ]
        }
      ],
      // //////////////
      // Mark layers //
      // //////////////
      marks: [
        {
          type: 'rule',
          encode: {
            update: {
              x: { value: 0 },
              x2: { value: props.graphWidth },
              y: { scale: 'y', value: 0 },
              stroke: { value: '#000000' },
              strokeWidth: { value: 1 },
              strokeOpacity: { value: 0.5 }
            }
          }
        },
        {
          type: 'rule',
          from: {
            data: 'characters_edited',
            transform: [{ type: 'sort', by: '-date' }]
          },
          encode:
          {
            update: {
              x: { scale: 'x', field: 'date' },
              y: { scale: 'y', field: 'characters' },
              y2: { scale: 'y', value: 0 },
              strokeWidth: { value: 2 },
              strokeOpacity: { value: 0.3 },
              stroke: [
                {
                  test: 'datum.characters > 0',
                  value: '#0000ff'
                },
                { value: '#ff0000' }
              ]
            }
          }
        },
        {
          name: 'circle_marks',
          type: 'symbol',
          from: {
            data: 'characters_edited',
            transform: [{ type: 'sort', by: '-date' }]
          },
          encode: { enter: {
            orient: { value: 'vertical' },
            opacity: { value: 0.5 }
          },
            update: {
              x: { scale: 'x', field: 'date' },
              y: { scale: 'y', field: 'characters' },
              y2: { scale: 'y' },
              size: { value: 100 },
              shape: { value: 'circle' },
              fill: [
                {
                  test: 'datum.characters > 0',
                  value: '#0000ff'
                },
                { value: '#ff0000' }
              ]
            }
          }
        }
      ]
    };

    // emded the visualization in the container with id vega-graph-article_id
    vegaEmbed(`#${props.graphid}`, vegaSpec, { defaultStyle: true, actions: { source: false } });
  };

    return (
      <div>
        <div id={props.graphid} />
      </div>
    );
  };

EditSizeGraph.propTypes = {
  graphid: PropTypes.string,
  graphWidth: PropTypes.number,
  graphHeight: PropTypes.number,
  articleData: PropTypes.array
};
export default EditSizeGraph;
