import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { Navigate, Route, Routes } from 'react-router-dom';
import Loading from '../common/loading.jsx';
import SubNavigation from '../common/sub_navigation.jsx';
import ArticleList from './article_list.jsx';
import AssignmentList from '../assignments/assignment_list.jsx';
import AvailableArticles from '../articles/available_articles.jsx';
import CategoryHandler from '../categories/category_handler.jsx';
import { fetchArticles, sortArticles, filterArticles, filterNewness, filterTrackedStatus } from '../../actions/articles_actions.js';
import { fetchAssignments } from '../../actions/assignment_actions';
import { getArticlesByPage } from '../../selectors';
import { delayFetchAssignmentsAndArticles } from '../util/helpers';
import ArticleUtils from '../../utils/article_utils.js';

const ArticlesHandler = (props) => {
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    delayFetchAssignmentsAndArticles(props, () => setLoading(false));
  }, [props.course, fetchArticles]);

  const hideAssignments = () => {
    const user = props.current_user;
    const assignments = props.assignments;
    const noAssignments = !assignments.filter(assignment => !assignment.user_id).length;
    const isAdminOrInstructor = user.admin || user.isAdvancedRole;

    return noAssignments && !isAdminOrInstructor;
  };

  if (!props.course || !props.course.home_wiki) {
    return <div />;
  }

  let categories;
  if (props.course.type === 'ArticleScopedProgram') {
    categories = <CategoryHandler course={props.course} current_user={props.current_user} />;
  }

  const project = props.course.home_wiki.project;

  const links = [
    {
      href: `/courses/${props.course.slug}/articles/edited`,
      text: ArticleUtils.I18n('edited', project)
    },
    {
      href: `/courses/${props.course.slug}/articles/assigned`,
      text: ArticleUtils.I18n('assigned', project)
    }
  ];

  if (loading) return <Loading />;
  // If there are assignments or the user is an admin, show the Articles Available button
  if (!hideAssignments()) {
    links.push({
      href: `/courses/${props.course.slug}/articles/available`,
      text: ArticleUtils.I18n('available', project)
    });
  }
  return (
    <div className="articles-view">
      <SubNavigation links={links} />

      <Routes>
        <Route path="edited" element={<ArticleList {...props} />} />
        <Route path="assigned" element={<AssignmentList {...props} />} />
        <Route
          path="available"
          element={(!loading && hideAssignments())
            // If at any point there are no available articles, redirect the user
            ? <Navigate to={`/courses/${props.course.slug}`} />
            : <AvailableArticles {...props} />
          }
        />
        <Route
          path="*" element={<Navigate
            replace
            to={{
                pathname: 'edited',
                search: window.location.search
              }}
          />
          }
        />
      </Routes>

      {categories}
    </div>
  );
};

ArticlesHandler.propTypes = {
  course_id: PropTypes.string,
  current_user: PropTypes.object,
  course: PropTypes.object,
  fetchArticles: PropTypes.func,
  limitReached: PropTypes.bool,
  limit: PropTypes.number,
  articles: PropTypes.array,
  loadingArticles: PropTypes.bool,
  assignments: PropTypes.array,
  loadingAssignments: PropTypes.bool
};

const mapStateToProps = state => ({
  limit: state.articles.limit,
  articles: getArticlesByPage(state),
  limitReached: state.articles.limitReached,
  wikis: state.articles.wikis,
  wikidataLabels: state.wikidataLabels.labels,
  loadingArticles: state.articles.loading,
  assignments: state.assignments.assignments,
  loadingAssignments: state.assignments.loading,
  newnessFilterEnabled: state.articles.newnessFilterEnabled,
  trackedStatusFilterEnabled: state.articles.trackedStatusFilterEnabled,
  trackedStatusFilter: state.articles.trackedStatusFilter,
  wikiFilter: state.articles.wikiFilter,
  newnessFilter: state.articles.newnessFilter
});

const mapDispatchToProps = {
  fetchArticles,
  sortArticles,
  filterArticles,
  filterNewness,
  filterTrackedStatus,
  fetchAssignments
};

export default connect(mapStateToProps, mapDispatchToProps)(ArticlesHandler);

