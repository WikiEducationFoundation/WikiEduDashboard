import React from 'react';
const CoursesTaughtGraph = React.createClass({
  propTypes: {
    statsData: React.PropTypes.array
  },
  render() {
    console.log('courses count');
    console.log(this.props.statsData);
    return (
      <div>
        <h5>
          CoursesTaughtGraph <br />
          CoursesTaughtGraph <br />
          CoursesTaughtGraph <br />
          CoursesTaughtGraph <br />
          CoursesTaughtGraph <br />
        </h5>
      </div>
    );
  }
});
export default CoursesTaughtGraph;
