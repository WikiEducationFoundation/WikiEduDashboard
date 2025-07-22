import React, { useEffect, useState } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import ContributionStats from './contribution_stats.jsx';
import CourseDetails from './course_details.jsx';
import UserUploads from './user_uploads.jsx';
import { fetchStats } from '../../actions/user_profile_actions.js';
import { fetchUserTrainingStatus } from '../../actions/training_status_actions';
import Loading from '../common/loading.jsx';
import UserTrainingStatus from './user_training_status.jsx';
import request from '../../utils/request';
import { useParams } from 'react-router-dom';

const UserProfile = () => {
  const dispatch = useDispatch();
  const stats = useSelector(state => state.userProfile.stats);
  const isLoading = useSelector(state => state.userProfile.isLoading);
  const userTrainingStatus = useSelector(state => state.userTrainingStatus);

  const [statsGraphsData, setStatsGraphsData] = useState();

  const params = useParams();
  const username = encodeURIComponent(params.username);

  const getData = () => {
    const statsdataUrl = `/stats_graphs.json?username=${username}`;
    request(statsdataUrl)
      .then(resp => resp.json())
      .then((data) => {
        setStatsGraphsData(data);
      });
  };

  useEffect(() => {
    dispatch(fetchUserTrainingStatus(username));
    dispatch(fetchStats(username));
    getData();
  }, []);

  if (isLoading) {
    return <Loading />;
  }

  return (
    <div>
      <ContributionStats params={params} stats={stats} statsGraphsData={statsGraphsData} />
      <CourseDetails courses={stats.courses_details} />
      <UserUploads uploads={stats.user_recent_uploads} />
      <UserTrainingStatus trainingModules={userTrainingStatus} />
    </div>
  );
};

export default UserProfile;
