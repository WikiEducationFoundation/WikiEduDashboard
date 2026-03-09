/* global vegaEmbed */
import React, { useEffect } from 'react';
import PropTypes from 'prop-types';

const renderGraph = (id, statsData) => {
  const vegaSpec = {
    width: 800,
    height: 250,
    padding: { top: 40, left: 70, right: 20, bottom: 50 },

    signals: [
        {
        name: 'binStep',
        value: 0.1,
        bind: { input: 'range', min: 0.01, max: 0.4, step: 0.01 }
        }
    ],

    data: [
        {
        name: 'points',
        values: statsData
        },
        {
        name: 'binned',
        source: 'points',
        transform: [
            {
            type: 'bin',
            field: 'value',
            extent: [0, 1],
            step: { signal: 'binStep' },
            nice: false
            },
            {
            type: 'aggregate',
            groupby: ['bin0', 'bin1'],
            ops: ['count'],
            as: ['count']
            }
        ]
        }
    ],

    scales: [
        {
        name: 'xscale',
        type: 'linear',
        range: 'width',
        domain: [0, 1]
        },
        {
        name: 'yscale',
        type: 'linear',
        range: 'height',
        domain: { data: 'binned', field: 'count' },
        zero: true,
        nice: true
        }
    ],

    axes: [
        { title: 'ai_likelihood', orient: 'bottom', scale: 'xscale' },
        { title: 'Count', orient: 'left', scale: 'yscale', tickCount: 5 }
    ],

    marks: [
        {
        type: 'rect',
        from: { data: 'binned' },
        encode: {
            update: {
                x: { scale: 'xscale', field: 'bin0' },
                x2: { scale: 'xscale', field: 'bin1' },
                y: { scale: 'yscale', field: 'count' },
                y2: { scale: 'yscale', value: 0 },
                fill: { value: 'steelblue' }
            },
            hover: { fill: { value: 'firebrick' } }
        }
        }
    ]
    };

  vegaEmbed(`#${id}`, vegaSpec, { defaultStyle: true, actions: { source: false } });
};

const LikelihoodDistributionGraph = (props) => {
  const id = `LikelihoodDistributionGraph${props.id}`;

  useEffect(() => {
    renderGraph(id, props.statsData);
  }, []);
    return (
      <div id={id} />
    );
};

LikelihoodDistributionGraph.displayName = 'LikelihoodDistributionGraph';
LikelihoodDistributionGraph.propTypes = {
  id: PropTypes.string,
  statsData: PropTypes.array,
};

export default LikelihoodDistributionGraph;
