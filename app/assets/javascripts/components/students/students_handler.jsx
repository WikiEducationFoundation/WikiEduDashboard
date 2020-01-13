import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';

import { sortUsers } from '../../actions/user_actions';
import { fetchAssignments } from '../../actions/assignment_actions';
import { fetchArticles } from '../../actions/articles_actions.js';
import Loading from '../common/loading';
import SubNavigation from '../common/sub_navigation';
import StudentsTabHandler from './containers/StudentsTabHandler.jsx';
import CourseUtils from '../../utils/course_utils.js';
import { getArticlesByNewness } from '../../selectors';
import { delayFetchAssignmentsAndArticles } from '../util/helpers';

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
        href: `/courses/${this.props.course.slug}/articles/edited`,
        // Don't forget to change this to conditionally show editors
        text: I18n.t('users.sub_navigation.student_overview')
      },
      {
        href: `/courses/${this.props.course.slug}/articles/assigned`,
        text: I18n.t('users.sub_navigation.article_assignments')
      },
      {
        href: `/courses/${this.props.course.slug}/articles/available`,
        text: I18n.t('users.sub_navigation.exercises_and_trainings')
      }
    ];

    return (
      <div id="users">
        <SubNavigation links={links} />

        <div className="section-header">
          <h3>{CourseUtils.i18n('students', this.props.course.string_prefix)}</h3>
        </div>
        <StudentsTabHandler {...this.props} sortSelect={this.sortSelect} />
      </div>
    );
  }
}
);

const mapStateToProps = state => ({
  articles: getArticlesByNewness(state),
  limit: state.articles.limit,
  loadingAssignments: state.assignments.loading,
  loadingArticles: state.articles.loading
});

const mapDispatchToProps = {
  sortUsers,
  fetchAssignments,
  fetchArticles
};

export default connect(mapStateToProps, mapDispatchToProps)(StudentsHandler);
