import React, { useEffect, useState } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { Routes, Route, useParams } from 'react-router-dom';
import ContributionStats from './contribution_stats.jsx';
import CourseDetails from './course_details.jsx';
import UserUploads from './user_uploads.jsx';
import { fetchStats } from '../../actions/user_profile_actions.js';
import { fetchUserTrainingStatus } from '../../actions/training_status_actions';
import Loading from '../common/loading.jsx';
import UserTrainingStatus from './user_training_status.jsx';
import request, { ensureOk } from '../../utils/request';
import UserDetails from './user_details.jsx';

const UserProfile = () => {
  const dispatch = useDispatch();
  const stats = useSelector(state => state.userProfile.stats);
  const isLoading = useSelector(state => state.userProfile.isLoading);
  const userTrainingStatus = useSelector(state => state.userTrainingStatus);

  const [statsGraphsData, setStatsGraphsData] = useState();

  const params = useParams();
  const username = encodeURIComponent(params.username);

  const getData = () => {
    const statsdataUrl = `/users/${username}/stats_graphs.json`;
    request(statsdataUrl)
      .then(resp => ensureOk(resp))
      .then(resp => resp.json())
      .then((data) => {
        setStatsGraphsData(data);
      })
      .catch(() => {
        // statsGraphsData stays unset; see Sentry issue PEONY-2NQ.
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
    <div className="user-profile-container">
      <Routes>
        <Route
          index
          element={<ContributionStats params={params} stats={stats} statsGraphsData={statsGraphsData} />}
        />
        <Route
          path="course-details"
          element={<CourseDetails courses={stats.courses_details} username={params.username} />}
        />
        <Route
          path="uploads"
          element={<UserUploads uploads={stats.user_recent_uploads} username={params.username} />}
        />
        <Route
          path="training"
          element={<UserTrainingStatus trainingModules={userTrainingStatus} />}
        />
        <Route
          path="stats/:metric"
          element={<UserDetails username={params.username} />}
        />
      </Routes>
    </div>
  );
};

export default UserProfile;