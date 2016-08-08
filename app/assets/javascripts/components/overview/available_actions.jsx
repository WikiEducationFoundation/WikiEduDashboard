import React from 'react';
import ServerActions from '../../actions/server_actions.js';
import CourseStore from '../../stores/course_store.coffee';

const getState = () => ({ course: CourseStore.getCourse() });

const AvailableActions = React.createClass({
  displayName: 'Actions',

  propTypes: {
    current_user: React.PropTypes.object
  },

  mixins: [CourseStore.mixin],

  getInitialState() {
    return getState();
  },

  storeDidChange() {
    return this.setState(getState());
  },

  join() {
    const passcode = prompt(I18n.t('courses.passcode_prompt'));
    if (passcode) {
      return window.location = this.state.course.enroll_url + passcode;
    }
  },

  leave() {
    if (confirm(I18n.t('courses.leave_confirmation'))) {
      const userObject = { user_id: this.props.current_user.id, role: 0 };
      return ServerActions.remove('user', this.state.course.slug, { user: userObject });
    }
  },

  delete() {
    const enteredTitle = prompt(I18n.t('courses.confirm_course_deletion', { title: this.state.course.title }));
    if (enteredTitle === this.state.course.title) {
      return ServerActions.deleteCourse(this.state.course.slug);
    } else if (enteredTitle) {
      return alert(I18n.t('courses.confirm_course_deletion_failed', { title: enteredTitle }));
    }
  },

  render() {
    let controls = [];
    const user = this.props.current_user;

    // If user has a role in the course or is an admin
    if ((user.role !== undefined) || user.admin) {
      if (user.role === 0) {
        controls.push((
          <p key="leave"><button onClick={this.leave} className="button">{I18n.t('courses.leave_course')}</button></p>
        ));
      }
      if ((user.role === 1 || user.admin) && !this.state.course.published) {
        controls.push((
          <p key="delete"><button className="button danger" onClick={this.delete}>{I18n.t('courses.delete_course')}</button></p>
        ));
      }
    // If user has no role or is logged out
    } else {
      controls.push((
        <p key="join">
          <button onClick={this.join} className="button">{I18n.t('courses.join_course')}</button>
        </p>
      ));
    }

    // If no controls are available
    if (controls.length === 0) {
      controls.push(
        <p key="none">{I18n.t('courses.no_available_actions')}</p>
      );
    }

    return (
      <div className="module">
        <div className="section-header">
          <h3>{I18n.t('courses.actions')}</h3>
        </div>
        <div className="module__data">
          {controls}
        </div>
      </div>
    );
  }
}
);

export default AvailableActions;
