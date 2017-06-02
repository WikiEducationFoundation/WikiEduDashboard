import React from 'react';
const CommmonUploadsGraph = React.createClass({
  propTypes: {
    statsData: React.PropTypes.array,
    graphWidth: React.PropTypes.number,
    graphHeight: React.PropTypes.number
  },

  render() {
    console.log('common uploads count');
    console.log(this.props.statsData);
    return (
      <div id ="stats_graph">
        <h5>ViewsCountGraph </h5>
      </div>
    );
  }
});
export default CommmonUploadsGraph;
