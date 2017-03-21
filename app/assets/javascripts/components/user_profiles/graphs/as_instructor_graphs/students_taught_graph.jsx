import React from 'react';

const StudentsTaughtGraph = React.createClass({
  propTypes: {
    statsData: React.PropTypes.array
  },
  render() {
    console.log('student count');
    console.log(this.props.statsData);
    return (
      <h5>
        StudentsTaughtGraph <br />
        StudentsTaughtGraph <br />
        StudentsTaughtGraph <br />
        StudentsTaughtGraph <br />
        StudentsTaughtGraph <br />
      </h5>
    );
  }
});

export default StudentsTaughtGraph;
