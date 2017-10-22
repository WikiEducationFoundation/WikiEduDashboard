import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import InstructorStats from './instructor_stats.jsx';
import StudentStats from './student_stats.jsx';
import ProfileStore from '../../stores/profile_store.js';
import ProfileActions from '../../actions/profile_actions.js';
import Loading from '../common/loading.jsx';

const getState = function () {
  const isStudent = $('#react_root').data('isstudent');
  const isInstructor = $('#react_root').data('isinstructor');

  return {
    isStudent: isStudent,
    isInstructor: isInstructor,
    statsGraphsData: null,
    stats: ProfileStore.getStats(),
    loading: ProfileStore.getLoadingStatus(),
  };
};
const ContributionStats = createReactClass({
  propTypes: {
    params: PropTypes.object
  },

  mixins: [ProfileStore.mixin], // adding store eventing to the component

  getInitialState() {
    return getState();
  },

  componentDidMount() {
    ProfileActions.fetch_stats(this.props.params.username);
    this.getData();
  },

  getData() {
    const username = this.props.params.username;
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

  storeDidChange() {
    this.setState(
      {
        stats: ProfileStore.getStats(),
        loading: ProfileStore.getLoadingStatus(),
      }
    );
  },

  render() {
    let contriStats;
    const graphWidth = 800;
    const graphHeight = 250;
    if (this.state.isInstructor.instructor) {
      contriStats = (
        <InstructorStats
          username = {this.props.params.username}
          stats = {this.state.stats}
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
          stats = {this.state.stats.as_student}
          statsGraphsData = {this.state.statsGraphsData}
          graphWidth = {graphWidth}
          graphHeight = {graphHeight}
        />
    );
    }
    const statistics = this.state.loading ? (
      <Loading />
      ) : (
        <div>
          {contriStats}
        </div>
      );
    return (
      <div>
        {statistics}
      </div>
    );
  }
});

export default ContributionStats;
