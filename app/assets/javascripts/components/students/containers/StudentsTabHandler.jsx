import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { Redirect, Route, Switch } from 'react-router-dom';

// Components
import Loading from '@components/common/loading.jsx';
import Overview from './Overview';
import Articles from './Articles';
import Exercises from './Exercises';

// Actions
import { notifyOverdue } from '~/app/assets/javascripts/actions/course_actions';
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

  notify() {
    if (confirm(I18n.t('wiki_edits.notify_overdue.confirm'))) {
      return this.props.notifyOverdue(this.props.course.slug);
    }
  },

  sortSelect(e) {
    return this.props.sortUsers(e.target.value);
  },

  render() {
    if (this.state.loading) return <Loading />;

    const prefix = CourseUtils.i18n('students', this.props.course.string_prefix);
    const props = {
      ...this.props,
      prefix,
      notify: this.notify,
      sortSelect: this.sortSelect
    };
    return (
      <div id="users">
        <Switch>
          <Route
            exact
            path="/courses/:course_school/:course_title/students/overview"
            render={() => <Overview {...props} />}
          />
          <Route
            exact
            path={[
              '/courses/:course_school/:course_title/students/articles',
              '/courses/:course_school/:course_title/students/articles/:username'
            ]}
            render={() => {
              return <Articles {...props} />;
            }}
          />
          <Route
            exact
            path="/courses/:course_school/:course_title/students/exercises"
            render={() => <Exercises {...props} />}
          />
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
  notifyOverdue,
  sortUsers,
  fetchAssignments,
  fetchArticles
};

export default connect(mapStateToProps, mapDispatchToProps)(StudentsHandler);
