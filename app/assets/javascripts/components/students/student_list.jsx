import React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';

import * as UIActions from '../../actions';

import Editable from '../high_order/editable.jsx';
import List from '../common/list.jsx';
import Student from './student.jsx';
import StudentDrawer from './student_drawer.jsx';
import EnrollButton from './enroll_button.jsx';

import UserStore from '../../stores/user_store.js';
import AssignmentStore from '../../stores/assignment_store.js';
import ServerActions from '../../actions/server_actions.js';
import CourseUtils from '../../utils/course_utils.js';

const getState = () =>
  ({
    users: UserStore.getFiltered({ role: 0 }),
    assignments: AssignmentStore.getModels()
  })
;

// FIXME: Remove this save function
const save = () => {
  return null;
};

const StudentList = React.createClass({
  displayName: 'StudentList',

  propTypes: {
    course_id: React.PropTypes.string,
    current_user: React.PropTypes.object,
    users: React.PropTypes.array,
    course: React.PropTypes.object,
    controls: React.PropTypes.func,
    editable: React.PropTypes.bool,
    openKey: React.PropTypes.string,
    actions: React.PropTypes.object
  },

  notify() {
    if (confirm(I18n.t('wiki_edits.notify_overdue.confirm'))) {
      return ServerActions.notifyOverdue(this.props.course_id);
    }
  },

  render() {
    const toggleDrawer = this.props.actions.toggleUI;
    const users = this.props.users.map(student => {
      const assignOptions = { user_id: student.id, role: 0 };
      const reviewOptions = { user_id: student.id, role: 1 };
      if (student.real_name) {
        const nameParts = student.real_name.split(' ');
        student.first_name = nameParts[0];
        student.last_name = nameParts.slice().pop();
      }

      const isOpen = this.props.openKey === `drawer_${student.id}`;
      return (
        <Student {...this.props}
          student={student}
          course={this.props.course}
          current_user={this.props.current_user}
          editable={this.props.editable}
          key={student.id}
          assigned={AssignmentStore.getFiltered(assignOptions)}
          reviewing={AssignmentStore.getFiltered(reviewOptions)}
          isOpen={isOpen}
          toggleDrawer={toggleDrawer}
        />
      );
    });

    const drawers = this.props.users.map(student => {
      const drawerKey = `drawer_${student.id}`;
      const isOpen = this.props.openKey === drawerKey;
      return (
        <StudentDrawer
          student={student}
          course_id={this.props.course.id}
          key={drawerKey}
          ref={drawerKey}
          isOpen={isOpen}
        />
      );
    });
    const elements = _.flatten(_.zip(users, drawers));

    let addStudent;
    if (this.props.course.published) {
      addStudent = <EnrollButton {...this.props} role={0} right_aligned={true} key="add_student" allowed={false} />;
    }

    let notifyOverdue;
    if (Features.wikiEd && this.props.users.length > 0 && (this.props.course.student_count - this.props.course.trained_count) > 0) {
      notifyOverdue = <button className="notify_overdue" onClick={this.notify} key="notify"></button>;
    }

    const keys = {
      username: {
        label: I18n.t('users.name'),
        desktop_only: false
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
      }
    };

    return (
      <div className="list__wrapper">
        {this.props.controls([addStudent, notifyOverdue], this.props.users.length < 1)}
        <List
          elements={elements}
          className="table--expandable table--hoverable"
          keys={keys}
          table_key="users"
          none_message={CourseUtils.i18n('students_none', this.props.course.string_prefix)}
          store={UserStore}
          editable={this.props.editable}
        />
      </div>
    );
  }
}
);

const mapStateToProps = state => ({
  openKey: state.ui.openKey
});

const mapDispatchToProps = dispatch => ({
  actions: bindActionCreators(UIActions, dispatch)
});

export default Editable(
  connect(mapStateToProps, mapDispatchToProps)(StudentList),
  [UserStore, AssignmentStore], save, getState, I18n.t('users.assign_articles'), I18n.t('users.assign_articles_done'), true
);
