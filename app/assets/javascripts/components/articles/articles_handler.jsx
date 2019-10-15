import React from 'react';
import PropTypes from 'prop-types';
import createReactClass from 'create-react-class';
import { connect } from 'react-redux';
import { withRouter } from 'react-router';
import { NavLink, Redirect, Route, Switch } from 'react-router-dom';

import Loading from '../common/loading.jsx';
import ArticleList from './article_list.jsx';
import AssignmentList from '../assignments/assignment_list.jsx';
import AvailableArticles from '../articles/available_articles.jsx';
import CategoryHandler from '../categories/category_handler.jsx';
import { fetchArticles, sortArticles, filterArticles, filterNewness, filterTrackedStatus } from '../../actions/articles_actions.js';
import { fetchAssignments } from '../../actions/assignment_actions';
import { getArticlesByTrackedStatus } from '../../selectors';
import { delayFetchAssignmentsAndArticles } from '../util/helpers';

export const ArticlesHandler = createReactClass({
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

  componentWillMount() {
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

    if (this.state.loading) return <Loading />;
    return (
      <div className="articles-view">
        <nav>
          <ul>
            <li>
              <NavLink
                to={`/courses/${this.props.course.slug}/articles/edited`}
                activeClassName="active"
                className="button"
              >
                {I18n.t('articles.edited')}
              </NavLink>
            </li>
            <li>
              <NavLink
                to={`/courses/${this.props.course.slug}/articles/assigned`}
                activeClassName="active"
                className="button"
              >
                {I18n.t('articles.assigned')}
              </NavLink>
            </li>
            <li>
              {
                !this.hideAssignments() && (
                  <NavLink
                    to={`/courses/${this.props.course.slug}/articles/available`}
                    activeClassName="active"
                    className="button"
                  >
                    {I18n.t('articles.available')}
                  </NavLink>
                )
              }
            </li>
          </ul>
        </nav>

        <Switch>
          <Route exact path="/courses/:course_school/:course_title/articles/edited" render={() => <ArticleList {...this.props} />} />
          <Route exact path="/courses/:course_school/:course_title/articles/assigned" render={() => <AssignmentList {...this.props} />} />
          <Route
            exact
            path="/courses/:course_school/:course_title/articles/available"
            render={() => {
              // If at any point there are no available articles, redirect the user
              if (!this.state.loading && this.hideAssignments()) {
                return <Redirect to={`/courses/${this.props.course.slug}`} />;
              }

              return <AvailableArticles {...this.props} />;
            }}
          />
          <Redirect
            to={{
              pathname: '/courses/:course_school/:course_title/articles/edited',
              search: this.props.location.search
            }}
          />
        </Switch>

        {categories}
      </div>
    );
  }
});

const mapStateToProps = state => ({
  limit: state.articles.limit,
  articles: getArticlesByTrackedStatus(state),
  limitReached: state.articles.limitReached,
  wikis: state.articles.wikis,
  wikidataLabels: state.wikidataLabels.labels,
  loadingArticles: state.articles.loading,
  assignments: state.assignments.assignments,
  loadingAssignments: state.assignments.loading,
  newnessFilterEnabled: state.articles.newnessFilterEnabled,
  trackedStatusFilterEnabled: state.articles.trackedStatusFilterEnabled,
  trackedStatusFilter: state.articles.trackedStatusFilter
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
export default withRouter(component);
