import React from 'react';
const ArticlesEditedGraph = React.createClass({
  propTypes: {
    statsData: React.PropTypes.array,
    graphWidth: React.PropTypes.number,
    graphHeight: React.PropTypes.number
  },

  render() {
    console.log('Article edited count');
    console.log(this.props.statsData);
    return (
      <div id ="stats_graph">
        <h5>ArticlesEditedGraph </h5>
      </div>
    );
  }
});
export default ArticlesEditedGraph;
