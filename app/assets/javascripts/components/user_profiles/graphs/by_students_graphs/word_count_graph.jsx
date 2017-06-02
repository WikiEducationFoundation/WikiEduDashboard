import React from 'react';
const WordCountGraph = React.createClass({
  propTypes: {
    statsData: React.PropTypes.array,
    graphWidth: React.PropTypes.number,
    graphHeight: React.PropTypes.number
  },

  render() {
    console.log('words added count');
    console.log(this.props.statsData);
    return (
      <div id ="stats_graph">
        <h5>WordCountGraph </h5>
      </div>
    );
  }
});
export default WordCountGraph;
