import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import StudentList from './student_list.jsx';
import UIActions from '../../actions/ui_actions.js';
import ServerActions from '../../actions/server_actions.js';
import CourseUtils from '../../utils/course_utils.js';

const StudentsHandler = createReactClass({
  displayName: 'StudentsHandler',

  propTypes: {
    course_id: PropTypes.string,
    current_user: PropTypes.object,
    course: PropTypes.object,
    children: PropTypes.node
  },

  componentWillMount() {
    return ServerActions.fetch('assignments', this.props.course_id);
  },
  sortSelect(e) {
    return UIActions.sort('users', e.target.value);
  },
  render() {
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
            </select>
          </div>
        </div>
        <StudentList {...this.props} />
        {this.props.children}
      </div>
    );
  }
}
);

export default StudentsHandler;
