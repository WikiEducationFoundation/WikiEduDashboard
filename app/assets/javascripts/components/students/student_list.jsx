import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import _ from 'lodash';
import moment from 'moment';

import { toggleUI, resetUI } from '../../actions';
import { notifyOverdue } from '../../actions/course_actions';
import { getStudentUsers, editPermissions } from '../../selectors';

import List from '../common/list.jsx';
import Student from './student.jsx';
import StudentDrawer from './student_drawer.jsx';
import EnrollButton from './enroll_button.jsx';
import NewAccountButton from '../enroll/new_account_button.jsx';
import CourseUtils from '../../utils/course_utils.js';

const StudentList = createReactClass({
  displayName: 'StudentList',

  propTypes: {
    course_id: PropTypes.string,
    current_user: PropTypes.object,
    students: PropTypes.array,
    course: PropTypes.object,
    editable: PropTypes.bool,
    openKey: PropTypes.string,
    toggleUI: PropTypes.func,
    resetUI: PropTypes.func,
    sortUsers: PropTypes.func,
    userRevisions: PropTypes.object.isRequired,
    trainingStatus: PropTypes.object.isRequired,
    notifyOverdue: PropTypes.func.isRequired,
    editPermissions: PropTypes.bool.isRequired
  },

  getInitialState() {
    return {
      showModal: false,
      editAssignments: false
    };
  },

  componentWillUnmount() {
    this.props.resetUI();
  },

  openModal() {
    this.setState({ showModal: true });
  },

  closeModal() {
    this.setState({ showModal: false });
  },

  toggleAssignmentEditingMode() {
    this.setState({ editAssignments: !this.state.editAssignments });
  },

  notify() {
    if (confirm(I18n.t('wiki_edits.notify_overdue.confirm'))) {
      return this.props.notifyOverdue(this.props.course.slug);
    }
  },

  // If the last update was not more than 7 days ago, show the 'recent edits'
  // count. Otherwise, it's out of date because the course is no longer being
  // updated.
  showRecent() {
    const lastUpdate = this.props.course.updates.last_update;
    if (!lastUpdate) { return false; }
    return moment.utc(lastUpdate.end_time).add(7, 'days').isAfter(moment());
  },

  render() {
    const showRecent = this.showRecent();
    const toggleDrawer = this.props.toggleUI;
    const students = this.props.students.map((student) => {
      if (student.real_name) {
        const nameParts = student.real_name.trim().toLowerCase().split(' ');
        student.first_name = nameParts[0];
        student.last_name = nameParts.slice().pop();
      }

      const isOpen = this.props.openKey === `drawer_${student.id}`;
      return (
        <Student
          student={student}
          course={this.props.course}
          current_user={this.props.current_user}
          editable={this.state.editAssignments}
          key={student.id}
          assignments={this.props.assignments}
          isOpen={isOpen}
          toggleDrawer={toggleDrawer}
          wikidataLabels={this.props.wikidataLabels}
          showRecent={showRecent}
        />
      );
    });

    const drawers = this.props.students.map((student) => {
      const drawerKey = `drawer_${student.id}`;
      const isOpen = this.props.openKey === drawerKey;
      return (
        <StudentDrawer
          student={student}
          course={this.props.course}
          key={drawerKey}
          ref={drawerKey}
          isOpen={isOpen}
          revisions={this.props.userRevisions[student.id]}
          trainingModules={this.props.trainingStatus[student.id]}
          wikidataLabels={this.props.wikidataLabels}
        />
      );
    });
    const elements = _.flatten(_.zip(students, drawers));
    let controls;
    if (this.props.editPermissions) {
      let assignArticlesButton;
      if (this.props.students.length > 0) {
        const assignLabel = this.state.editAssignments ? I18n.t('users.assign_articles_done') : I18n.t('users.assign_articles');
        assignArticlesButton = <button className="dark button" onClick={this.toggleAssignmentEditingMode} key="assign_articles">{assignLabel}</button>;
      }

      let addStudent;
      if (this.props.course.published) {
        addStudent = <EnrollButton {...this.props} users={this.props.students} role={0} key="add_student" allowed={false} />;
      }

      let requestAccountsButton;
      if (this.props.course.account_requests_enabled && this.props.course.published) {
        requestAccountsButton = <NewAccountButton key="request_accounts" course={this.props.course} passcode={this.props.course.passcode} currentUser={this.props.current_user} />;
      }

      let notifyOverdueButton;
      if (Features.wikiEd && this.props.students.length > 0 && (this.props.course.student_count - this.props.course.trained_count) > 0) {
        notifyOverdueButton = <button className="notify_overdue" onClick={this.notify} key="notify" />;
      }

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

      const sortButton = (
        <div className="sort-select users">
          <select className="sorts" name="sorts" onChange={this.props.sortSelect}>
            <option value="username">{I18n.t('users.username')}</option>
            {firstNameSorting}
            {lastNameSorting}
            <option value="character_sum_ms">{I18n.t('users.characters_added_mainspace')}</option>
            <option value="character_sum_us">{I18n.t('users.characters_added_userspace')}</option>
            <option value="character_sum_draft">{I18n.t('users.characters_added_draftspace')}</option>
            <option value="references_count">{I18n.t('users.references_count')}</option>
          </select>
        </div>
      );

      controls = (
        <div className="users-control">
          {assignArticlesButton}
          {addStudent}
          {requestAccountsButton}
          {notifyOverdueButton}
          {sortButton}
        </div>
      );
    }

    const keys = {
      username: {
        label: I18n.t('users.name'),
        desktop_only: false,
        sortable: true,
      },
      assignment_title: {
        label: I18n.t('users.assigned'),
        desktop_only: true,
        sortable: false
      },
      reviewing_title: {
        label: I18n.t('users.reviewing'),
        desktop_only: true,
        sortable: false
      },
      recent_revisions: {
        label: I18n.t('users.recent_revisions'),
        desktop_only: true,
        sortable: true,
        info_key: 'users.revisions_doc'
      },
      character_sum_ms: {
        label: I18n.t('users.chars_added'),
        desktop_only: true,
        sortable: true,
        info_key: 'users.character_doc'
      },
      references_count: {
        label: I18n.t('users.references_count'),
        desktop_only: true,
        sortable: true,
        info_key: 'metrics.references_doc'
      },
      total_uploads: {
        label: I18n.t('users.total_uploads'),
        desktop_only: true,
        sortable: true,
        info_key: 'users.uploads_doc'
      }
    };
    if (!showRecent) {
      delete keys.recent_revisions;
    }
    if (this.props.sort.key && keys[this.props.sort.key]) {
      const order = (this.props.sort.sortKey) ? 'asc' : 'desc';
      keys[this.props.sort.key].order = order;
    }
    return (
      <div className="list__wrapper">
        {controls}
        <List
          elements={elements}
          className="table--expandable table--hoverable"
          keys={keys}
          table_key="users"
          none_message={CourseUtils.i18n('students_none', this.props.course.string_prefix)}
          editable={this.state.editAssignments}
          sortBy={this.props.sortUsers}
          stickyHeader={true}
          sortable={true}
        />
      </div>
    );
  }
});

const mapStateToProps = state => ({
  openKey: state.ui.openKey,
  students: getStudentUsers(state),
  assignments: state.assignments.assignments,
  sort: state.users.sort,
  userRevisions: state.userRevisions,
  trainingStatus: state.trainingStatus,
  editPermissions: editPermissions(state),
  wikidataLabels: state.wikidataLabels.labels
});

const mapDispatchToProps = {
  toggleUI,
  resetUI,
  notifyOverdue
};

export default connect(mapStateToProps, mapDispatchToProps)(StudentList);
