import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { Navigate, Route, Routes } from 'react-router-dom';
import withRouter from '../../util/withRouter';
// Components
import Loading from '@components/common/loading.jsx';
import Overview from './Overview';
import Articles from './Articles';

// Actions
import { notifyOverdue } from '~/app/assets/javascripts/actions/course_actions';
import { sortUsers } from '~/app/assets/javascripts/actions/user_actions';
import { fetchAssignments } from '~/app/assets/javascripts/actions/assignment_actions';
import { fetchArticles } from '~/app/assets/javascripts/actions/articles_actions.js';

// Utils
import CourseUtils from '~/app/assets/javascripts/utils/course_utils.js';
import { getArticlesByNewness } from '~/app/assets/javascripts/selectors';
import { delayFetchAssignmentsAndArticles } from '@components/util/helpers';

const StudentsTabHandler = ({
  course_id,
  current_user,
  course,
  loadingAssignments,
}) => {
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    delayFetchAssignmentsAndArticles({ fetchAssignments, fetchArticles }, () => setLoading(false));
  }, [fetchAssignments, fetchArticles]);

  const notify = () => {
    if (confirm(I18n.t('wiki_edits.notify_overdue.confirm'))) {
      return notifyOverdue(course.slug);
    }
  };

  const sortSelect = (e) => { sortUsers(e.target.value); };

  if (loading) return <Loading />;

  const prefix = CourseUtils.i18n('students', course.string_prefix);
  const props = {
    course_id,
    current_user,
    course,
    sortUsers,
    fetchAssignments,
    loadingAssignments,
    prefix,
    notify,
    sortSelect
  };

  return (
    <div id="users">
      <Routes>
        <Route path="overview/*" element={<Overview {...props} />} />
        <Route path="articles/*" element={<Articles {...props} />} />
        <Route path="*" element={<Navigate replace to="overview"/>} />
      </Routes>
    </div>
  );
};

StudentsTabHandler.propTypes = {
  course_id: PropTypes.string,
  current_user: PropTypes.object,
  course: PropTypes.object,
  sortUsers: PropTypes.func.isRequired,
  fetchAssignments: PropTypes.func.isRequired,
  loadingAssignments: PropTypes.bool,
  notifyOverdue: PropTypes.func.isRequired,
  fetchArticles: PropTypes.func.isRequired,
};

const mapStateToProps = state => ({
  articles: getArticlesByNewness(state),
  course: state.course,
  limit: state.articles.limit,
  loadingAssignments: state.assignments.loading,
  loadingArticles: state.articles.loading,
  wikidataLabels: state.wikidataLabels.labels,
});

const mapDispatchToProps = {
  notifyOverdue,
  sortUsers,
  fetchAssignments,
  fetchArticles
};

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(StudentsTabHandler));
