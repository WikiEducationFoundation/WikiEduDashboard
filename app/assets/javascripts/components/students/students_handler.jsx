import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';

import { sortUsers } from '../../actions/user_actions';
import { fetchAssignments } from '../../actions/assignment_actions';
import { fetchArticles } from '../../actions/articles_actions.js';
import Loading from '../common/loading';
import StudentList from './student_list.jsx';
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

  componentWillMount() {
    delayFetchAssignmentsAndArticles(this.props, () => this.setState({ loading: false }));
  },

  sortSelect(e) {
    return this.props.sortUsers(e.target.value);
  },

  render() {
    if (this.state.loading) return <Loading />;

    let firstNameSorting;
    let lastNameSorting;
    if (this.props.current_user && (this.props.current_user.admin || this.props.current_user.role > 0)) {
      firstNameSorting = (
        <option value="first_name">{I18n.t('users.first_name')}</option>
      );
      lastNameSorting = (
        <option value="last_name">{I18n.t('users.last_name')}</option>
      );
    }

    return (
      <div id="users">
        <div className="section-header">
          <h3>{CourseUtils.i18n('students', this.props.course.string_prefix)}</h3>
          <div className="sort-select">
            <select className="sorts" name="sorts" onChange={this.sortSelect}>
              <option value="username">{I18n.t('users.username')}</option>
              {firstNameSorting}
              {lastNameSorting}
              <option value="character_sum_ms">{I18n.t('users.characters_added_mainspace')}</option>
              <option value="character_sum_us">{I18n.t('users.characters_added_userspace')}</option>
              <option value="character_sum_draft">{I18n.t('users.characters_added_draftspace')}</option>
              <option value="references_count">{I18n.t('users.references_count')}</option>
            </select>
          </div>
        </div>
        <StudentList {...this.props} />
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
