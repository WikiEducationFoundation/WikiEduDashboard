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
import UserTrainingStatus from './user_training_status.jsx';
import request from '../../utils/request';
import withRouter from '../util/withRouter';

const UserProfile = createReactClass({
  propTypes: {
    match: PropTypes.object,
    fetchStats: PropTypes.func.isRequired,
    stats: PropTypes.object.isRequired,
    isLoading: PropTypes.bool.isRequired,
    fetchUserTrainingStatus: PropTypes.func.isRequired
  },

  getInitialState() {
    return {};
  },

  componentDidMount() {
    const username = encodeURIComponent(this.props.router.params.username);
    this.props.fetchUserTrainingStatus(username);
    this.props.fetchStats(username);
    this.getData();
  },

  getData() {
    const username = encodeURIComponent(this.props.router.params.username);
    const statsdataUrl = `/stats_graphs.json?username=${username}`;

    request(statsdataUrl)
      .then(resp => resp.json())
      .then((data) => {
        this.setState({ statsGraphsData: data });
      });
  },

  render() {
    if (this.props.isLoading) {
      return <Loading />;
    }

    return (
      <div>
        <ContributionStats params={this.props.router.params} stats={this.props.stats} statsGraphsData={this.state.statsGraphsData} />
        <CourseDetails courses={this.props.stats.courses_details} />
        <UserUploads uploads={this.props.stats.user_recent_uploads} />
        <UserTrainingStatus trainingModules={this.props.trainingStatus} />
      </div>
    );
  }
});

const mapStateToProps = state => ({
  stats: state.userProfile.stats,
  isLoading: state.userProfile.isLoading,
  trainingStatus: state.userTrainingStatus
});

const mapDispatchToProps = ({
  fetchStats,
  fetchUserTrainingStatus
});

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(UserProfile));
