import React from 'react';
import { connect } from 'react-redux';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import InstructorStats from './instructor_stats.jsx';
import StudentStats from './student_stats.jsx';
import { fetchStats } from '../../actions/user_profile_actions.js';
import Loading from '../common/loading.jsx';

const getState = function () {
  const isStudent = $('#react_root').data('isstudent');
  const isInstructor = $('#react_root').data('isinstructor');

  return {
    isStudent: isStudent,
    isInstructor: isInstructor,
    statsGraphsData: null
  };
};

const ContributionStats = createReactClass({
  propTypes: {
    params: PropTypes.object,
    fetchStats: PropTypes.func.isRequired,
    stats: PropTypes.object.isRequired,
    isLoading: PropTypes.bool.isRequired
  },

  getInitialState() {
    return getState();
  },

  componentDidMount() {
    this.props.fetchStats(encodeURIComponent(this.props.params.username));
    this.getData();
  },

  getData() {
    const username = encodeURIComponent(this.props.params.username);
    const statsdataUrl = `/stats_graphs.json?username=${username}`;
    $.ajax(
      {
        dataType: 'json',
        url: statsdataUrl,
        success: (data) => {
          this.setState({
            statsGraphsData: data
          });
        }
      });
  },


  render() {
    if (this.props.isLoading) {
      return <Loading />;
    }
    let contriStats;
    const graphWidth = 800;
    const graphHeight = 250;
    if (this.state.isInstructor.instructor) {
      contriStats = (
        <InstructorStats
          username = {this.props.params.username}
          stats = {this.props.stats}
          isStudent = {this.state.isStudent.student}
          statsGraphsData = {this.state.statsGraphsData}
          graphWidth = {graphWidth}
          graphHeight = {graphHeight}
        />
      );
    }
    else if (this.state.isStudent.student) {
      contriStats = (
        <StudentStats
          username = {this.props.params.username}
          stats = {this.props.stats.as_student}
          statsGraphsData = {this.state.statsGraphsData}
          graphWidth = {graphWidth}
          graphHeight = {graphHeight}
        />
    );
    }

    return (
      <div>
        {contriStats}
      </div>
    );
  }
});

const mapStateToProps = state => ({
  stats: state.userProfile.stats,
  isLoading: state.userProfile.isLoading
});

const mapDispatchToProps = ({
  fetchStats
});

export default connect(mapStateToProps, mapDispatchToProps)(ContributionStats);
