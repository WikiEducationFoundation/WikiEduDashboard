import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import InstructorStats from './instructor_stats.jsx';
import StudentStats from './student_stats.jsx';

const getState = function () {
  const isStudent = JSON.parse(document.querySelector('#react_root')?.dataset.isstudent);
  const isInstructor = JSON.parse(document.querySelector('#react_root')?.dataset.isinstructor);
  return {
    isStudent: isStudent,
    isInstructor: isInstructor,
    statsGraphsData: null
  };
};

const ContributionStats = createReactClass({
  propTypes: {
    params: PropTypes.object,
    stats: PropTypes.object.isRequired
  },

  getInitialState() {
    return getState();
  },

  render() {
    let contriStats;
    const graphWidth = 800;
    const graphHeight = 250;
    if (this.state.isInstructor.instructor) {
      contriStats = (
        <InstructorStats
          username = {this.props.params.username}
          stats = {this.props.stats}
          isStudent = {this.state.isStudent.student}
          statsGraphsData = {this.props.statsGraphsData}
          graphWidth = {graphWidth}
          graphHeight={graphHeight}
          maxProject = {this.props.stats.max_project}
        />
      );
    } else if (this.state.isStudent.student) {
      contriStats = (
        <StudentStats
          username = {this.props.params.username}
          stats = {this.props.stats.as_student}
          statsGraphsData = {this.props.statsGraphsData}
          graphWidth = {graphWidth}
          graphHeight={graphHeight}
          maxProject = {this.props.stats.max_project}
        />
    );
    }

    return (
      <div id="statistics">
        <h3>{I18n.t('users.contribution_statistics')}</h3>
        {contriStats}
      </div>
    );
  }
});

export default ContributionStats;
