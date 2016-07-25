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
  },

  hideGraph() {
    this.setState({ showGraph: false });
  },

  graphId() {
    return `vega-graph-${this.props.article.id}`;
  },

  renderGraph() {
    this.showGraph();
    const articleId = this.props.article.id;
    const vlSpec = {
      // TODO: get data from json endpoint
      data: { url: `/articles/${articleId}.json` },
      mark: 'circle',
      encoding: {
        x: {
          field: 'date',
          timeUnite: 'day',
          type: 'temporal'
        },
        y: {
          field: 'wp10',
          type: 'quantitative'
        }
      }
    };
    const embedSpec = {
      mode: 'vega-lite', // Instruct Vega-Embed to use the Vega-Lite compiler
      spec: vlSpec
    };
    vg.embed(`#${this.graphId()}`, embedSpec);
  },

  render() {
    let style;
    let button;
    if (this.state.showGraph) {
      style = '';
      button = <button onClick={this.hideGraph} className="button dark">Hide graph</button>;
    } else {
      style = ' hidden';
      button = <button onClick={this.renderGraph} className="button dark">Show graph</button>;
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
