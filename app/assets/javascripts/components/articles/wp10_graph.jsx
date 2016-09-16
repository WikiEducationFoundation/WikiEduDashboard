/* global vg */
import React from 'react';

const Wp10Graph = React.createClass({
  displayName: 'Wp10Graph',

  propTypes: {
    article: React.PropTypes.object
  },

  getInitialState() {
    return { showGraph: false };
  },

  showGraph() {
    this.setState({ showGraph: true });
    if (!this.state.rendered) {
      this.renderGraph();
    }
  },

  hideGraph() {
    this.setState({ showGraph: false });
  },

  graphId() {
    return `vega-graph-${this.props.article.id}`;
  },

  renderGraph() {
    const articleId = this.props.article.id;
    const graphWidth = 500;
    const graphHeight = 300;
    const vegaSpec = {
      width: graphWidth,
      height: graphHeight,
      padding: 'auto',
      data: [
        {
          name: 'wp10_scores',
          url: `/articles/${articleId}.json`,
          format: { type: 'json', parse: { date: 'date', wp10: 'number' } },
          transform: [{
            type: 'filter',
            test: 'datum[\"date\"] !== null && !isNaN(datum[\"date\"]) && datum[\"wp10\"] !== null && !isNaN(datum[\"wp10\"])'
          }]
        }
      ],
      marks: [
        {
          name: 'area_marks',
          type: 'area',
          from: {
            data: 'wp10_scores',
            transform: [{ type: 'sort', by: '-date' }]
          },
          properties: { update: {
            orient: { value: 'vertical' },
            x: { scale: 'x', field: 'date' },
            y: { scale: 'y', field: 'wp10' },
            y2: { scale: 'y', value: 0 },
            fill: { value: '#676EB4' },
            opacity: { value: 0.7 },
            interpolate: { value: 'step-before' }
          } }
        },
        {
          name: 'circle_marks',
          type: 'symbol',
          from: {
            data: 'wp10_scores',
            transform: [{ type: 'sort', by: '-date' }]
          },
          properties: { update: {
            x: { scale: 'x', field: 'date' },
            y: { scale: 'y', field: 'wp10' },
            size: { value: 100 },
            shape: { value: 'circle' },
            fill: { value: '#359178' },
            opacity: { value: 0.7 }
          } }
        }
      ],
      scales: [
        {
          name: 'x',
          type: 'time',
          domain: {
            fields: [{
              data: 'wp10_scores',
              field: 'date',
              sort: { field: 'date', op: 'min' }
            }]
          },
          rangeMin: 0,
          rangeMax: graphWidth,
          round: true
        },
        {
          name: 'y',
          type: 'linear',
          domain: [0, 100, 0, 100],
          rangeMin: graphHeight,
          rangeMax: 0,
          round: true,
          nice: true,
          zero: false
        }
      ],
      axes: [
        {
          type: 'x',
          scale: 'x',
          grid: true,
          layer: 'back',
          ticks: 5,
          title: 'Date',
          properties: {
            labels: {
              text: { template: '{{datum[\"data\"] | time:\'%b %d\'}}' },
              angle: { value: 0 }
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
          title: I18n.t('articles.wp10')
        }
      ]
    };

    const embedSpec = {
      mode: 'vega',
      spec: vegaSpec,
      actions: false
    };
    vg.embed(`#${this.graphId()}`, embedSpec);
    this.setState({ rendered: true });
  },

  render() {
    // Only render the button if it is an en.wikipedia article, since only
    // those articles have wp10 scores.
    if (!this.props.article.url.match(/en.wikipedia/)) {
      return <div></div>;
    }

    let style;
    let button;
    if (this.state.showGraph) {
      style = '';
      button = <button onClick={this.hideGraph} className="button dark">Hide graph</button>;
    } else {
      style = ' hidden';
      button = <button onClick={this.showGraph} className="button dark">Show graph</button>;
    }
    const className = `vega-graph ${style}`;
    return (
      <div>
        {button}
        <div id={this.graphId()} className={className} />
      </div>
    );
  }
});

export default Wp10Graph;
