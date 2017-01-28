/* global vg */
import React from 'react';
import OnClickOutside from 'react-onclickoutside';

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

  handleClickOutside() {
    this.hideGraph();
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
      padding: { top: 40, left: 70, right: 20, bottom: 35 },
      // ////////////////
      // articlesize ////
      // ///////////////

      // //////////////////
      // Scales and Axes //
      // //////////////////
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
          domain: {
            data: 'wp10_scores',
            field: 'characters'
          },
          rangeMin: graphHeight,
          rangeMax: 0,
          round: true,
          nice: true,
          zero: true
        },
        {
          name: 'color',
          type: 'ordinal',
          domain: ["characters", "wp10"],
          range: ["#359178", "#33f"]
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
              text: { template: '{{datum["data"] | time:\'%b %d\'}}' },
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
      ],
      // ///////////////
      // Data Sources //
      // ///////////////
      data: [
        {
          name: 'wp10_scores',
          url: `/articles/wp10.json?article_id=${articleId}`,
          format: { type: 'json', parse: { date: 'date', wp10: 'number', characters: 'number' } },
          transform: [{
            type: 'filter',
            test: 'datum["date"] !== null && !isNaN(datum["date"]) && datum["wp10"] !== null && !isNaN(datum["wp10"]) && datum["characters"] !== null && !isNaN(datum["characters"])'
          }
          ]
        }
      ],
      // //////////////
      // Mark layers //
      // //////////////
      marks: [
        // Step graph fill area below scores
        {
          name: 'area_marks',
          type: 'area',
          from: {
            data: 'wp10_scores',
            transform: [{ type: 'sort', by: '-date' }]
          },
          properties: { enter: {
            orient: { value: 'vertical' },
            opacity: { value: 0.7 },
            interpolate: { value: 'step-before' }
          },
            update: {
              x: { scale: 'x', field: 'date' },
              y: { scale: 'y', field: 'characters' },
              y2: { scale: 'y', value: 0 },
              fill: [
                {
                  test: "datum.characters > datum.index",
                  value: 'blue'
                },
                { value: 'red' }
              ]
            }
          }
        }
      ]
    };

    const embedSpec = {
      mode: 'vega', // instruct Vega-Embed to use vega compiler.
      parameters: [
        {
          signal: "graph",
          type: "radio",
          value: "structural completeness",
          options: ["article size", "structural completeness"]
        }
      ],
      spec: vegaSpec,
      actions: false
    };
    // emded the visualization in the container with id vega-graph-article_id
    vg.embed(`#${this.graphId()}`, embedSpec); // Callback receiving View instance and parsed Vega spec
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
      style = ' hidden'; // hides the element, but it still takes up space in the layout.
      button = <button onClick={this.showGraph} className="button dark">Show Structural Completeness</button>;
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

export default OnClickOutside(Wp10Graph); // high order component to listen to clicks outside this element
