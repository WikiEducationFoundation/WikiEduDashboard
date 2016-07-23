import React from 'react';

const Wp10Graph = React.createClass({
  displayName: 'Wp10Graph',

  propTypes: {
    article: React.PropTypes.object,
    course: React.PropTypes.object
  },

  graphId() {
    return `${this.props.article.article_title}-graph`;
  },

  componentDidMount: function() {
    const vlSpec = {
      // TODO: get data from json endpoint
      data: { values: [{"a": 1, "b": 2}, {"a": 2, "b": 7}, {"a": 3, "b": 4}] },
      mark: "line",
      encoding: {
        x: {
          "field": "a",
          "type": "quantitative"
        },
        y: {
          "field": "b",
          "type": "quantitative"
        }
      }
    };
    const embedSpec = {
      mode: "vega-lite",  // Instruct Vega-Embed to use the Vega-Lite compiler
      spec: vlSpec
    };
    vg.embed(`#${this.graphId()}`, embedSpec);
  },

  render() {
    return (
      <div id={this.graphId()} />
    );
  }
});

export default Wp10Graph;
