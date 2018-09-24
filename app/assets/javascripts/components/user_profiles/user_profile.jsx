import React from 'react';
import createReactClass from 'create-react-class';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import ContributionStats from './contribution_stats.jsx';
import CourseDetails from './course_details.jsx';
import UserUploads from './user_uploads.jsx';
import { fetchStats } from '../../actions/user_profile_actions.js';
import { fetchUserTrainingStatus } from '../../actions/training_status_actions';
import Loading from '../common/loading.jsx';
import TrainingStatus from '../students/training_status.jsx';

const UserProfile = createReactClass({
  propTypes: {
    params: PropTypes.object,
    fetchStats: PropTypes.func.isRequired,
    stats: PropTypes.object.isRequired,
    isLoading: PropTypes.bool.isRequired,
    fetchUserTrainingStatus: PropTypes.func.isRequired
  },

  getInitialState() {
    return {};
  },

  componentDidMount() {
    const username = encodeURIComponent(this.props.params.username);
    this.props.fetchUserTrainingStatus(username);
    this.props.fetchStats(username);
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

    return (
      <div>
        <ContributionStats params={this.props.params} stats={this.props.stats} statsGraphsData={this.state.statsGraphsData} />
        <CourseDetails courses={this.props.stats.courses_details} />
        <UserUploads uploads={this.props.stats.user_recent_uploads} />
        <div>
          <br />
          <h3>Training Status</h3>
          <TrainingStatus trainingModules={this.props.trainingStatus} />
        </div>
      </div>
    );
  }
});

const mapStateToProps = state => ({
  stats: state.userProfile.stats,
  isLoading: state.userProfile.isLoading,
  trainingStatus: state.trainingStatus.user
});

const mapDispatchToProps = ({
  fetchStats,
  fetchUserTrainingStatus
});

export default connect(mapStateToProps, mapDispatchToProps)(UserProfile);
