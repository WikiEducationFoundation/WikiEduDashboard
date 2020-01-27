import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { Redirect, Route, Switch } from 'react-router-dom';

// Components
import Loading from '@components/common/loading.jsx';
import SubNavigation from '@components/common/sub_navigation.jsx';
import Overview from './Overview';
import Articles from './Articles';
import Exercises from './Exercises';


// Actions
import { sortUsers } from '~/app/assets/javascripts/actions/user_actions';
import { fetchAssignments } from '~/app/assets/javascripts/actions/assignment_actions';
import { fetchArticles } from '~/app/assets/javascripts/actions/articles_actions.js';

// Utils
import CourseUtils from '~/app/assets/javascripts/utils/course_utils.js';
import { getArticlesByNewness } from '~/app/assets/javascripts/selectors';
import { delayFetchAssignmentsAndArticles } from '@components/util/helpers';

const StudentsHandler = createReactClass({
  displayName: 'StudentsHandler',

  propTypes: {
    course_id: PropTypes.string,
    current_user: PropTypes.object,
    course: PropTypes.object,
    sortUsers: PropTypes.func.isRequired,
    fetchAssignments: PropTypes.func.isRequired,
    loadingAssignments: PropTypes.bool
  },

  getInitialState() {
    return { loading: true };
  },

  UNSAFE_componentWillMount() {
    delayFetchAssignmentsAndArticles(this.props, () => this.setState({ loading: false }));
  },

  sortSelect(e) {
    return this.props.sortUsers(e.target.value);
  },

  render() {
    if (this.state.loading) return <Loading />;

    const links = [
      {
        href: `/courses/${this.props.course.slug}/students/overview`,
        // Don't forget to change this to conditionally show editors
        text: I18n.t('users.sub_navigation.student_overview')
      },
      {
        href: `/courses/${this.props.course.slug}/students/articles`,
        text: I18n.t('users.sub_navigation.article_assignments')
      },
      {
        href: `/courses/${this.props.course.slug}/students/exercises`,
        text: I18n.t('users.sub_navigation.exercises_and_trainings')
      }
    ];

    const isAdvancedRole = this.props.current_user.isAdvancedRole;
    return (
      <div id="users">
        {
          isAdvancedRole && <SubNavigation links={links} />
        }

        <div className="section-header">
          <h3>{CourseUtils.i18n('students', this.props.course.string_prefix)}</h3>
        </div>

        <Switch>
          <Route
            exact
            path="/courses/:course_school/:course_title/students/overview"
            render={() => {
              return <Overview {...this.props} sortSelect={this.sortSelect} />;
            }}
          />
          {
            isAdvancedRole && (
              <Route
                exact
                path="/courses/:course_school/:course_title/students/articles"
                render={() => {
                  return <Articles {...this.props} />;
                }}
              />
            )
          }
          {
            isAdvancedRole && (
              <Route
                exact
                path="/courses/:course_school/:course_title/students/exercises"
                render={() => {
                  return <Exercises {...this.props} sortSelect={this.sortSelect} />;
                }}
              />
            )
          }
          <Redirect
            to={{
              pathname: '/courses/:course_school/:course_title/students/overview'
            }}
          />
        </Switch>
      </div>
    );
  }
}
);

const mapStateToProps = state => ({
  articles: getArticlesByNewness(state),
  course: state.course,
  limit: state.articles.limit,
  loadingAssignments: state.assignments.loading,
  loadingArticles: state.articles.loading,
  wikidataLabels: state.wikidataLabels.labels,
});

const mapDispatchToProps = {
  sortUsers,
  fetchAssignments,
  fetchArticles
};

export default connect(mapStateToProps, mapDispatchToProps)(StudentsHandler);
