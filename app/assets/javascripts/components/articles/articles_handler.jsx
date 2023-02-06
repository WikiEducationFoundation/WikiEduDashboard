import React from 'react';
import PropTypes from 'prop-types';
import createReactClass from 'create-react-class';
import { connect } from 'react-redux';
import withRouter from '../util/withRouter';
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

export const ArticlesHandler = withRouter(createReactClass({
  displayName: 'ArticlesHandler',

  propTypes: {
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
  },

  getInitialState() {
    return {
      loading: true
    };
  },

  componentDidMount() {
    delayFetchAssignmentsAndArticles(this.props, () => this.setState({ loading: false }));
  },

  hideAssignments() {
    const user = this.props.current_user;
    const assignments = this.props.assignments;
    const noAssignments = !assignments.filter(assignment => !assignment.user_id).length;
    const isAdminOrInstructor = user.admin || user.isAdvancedRole;

    return noAssignments && !isAdminOrInstructor;
  },

  render() {
    // FIXME: These props should be required, and this component should not be
    // mounted in the first place if they are not available.
    if (!this.props.course || !this.props.course.home_wiki) { return <div />; }

    let categories;
    if (this.props.course.type === 'ArticleScopedProgram') {
      categories = <CategoryHandler course={this.props.course} current_user={this.props.current_user} />;
    }

     const project = this.props.course.home_wiki.project;

    const links = [
      {
        href: `/courses/${this.props.course.slug}/articles/edited`,
        text: ArticleUtils.I18n('edited', project)
      },
      {
        href: `/courses/${this.props.course.slug}/articles/assigned`,
        text: ArticleUtils.I18n('assigned', project)
      }
    ];

    if (this.state.loading) return <Loading />;
    // If there are assignments or the user is an admin, show the Articles Available button
    if (!this.hideAssignments()) {
      links.push({
        href: `/courses/${this.props.course.slug}/articles/available`,
        text: ArticleUtils.I18n('available', project)
      });
    }
    return (
      <div className="articles-view">
        <SubNavigation links={links} />

        <Routes>
          <Route path="edited" element={<ArticleList {...this.props} />} />
          <Route path="assigned" element={<AssignmentList {...this.props} />} />
          <Route
            path="available"
            element={(!this.state.loading && this.hideAssignments())
              // If at any point there are no available articles, redirect the user
              ? <Navigate to={`/courses/${this.props.course.slug}`} />
              : <AvailableArticles {...this.props} />
            }
          />
          <Route
            path="*" element={<Navigate
              replace
              to={{
                  pathname: 'edited',
                  search: this.props.router.location.search
                }}
            />
            }
          />
        </Routes>

        {categories}
      </div>
    );
  }
}));

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

const connector = connect(mapStateToProps, mapDispatchToProps);
const component = connector(ArticlesHandler);
export default component;
