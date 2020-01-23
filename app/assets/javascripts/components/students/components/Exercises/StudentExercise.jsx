import React from 'react';
import createReactClass from 'create-react-class';
import { Link } from 'react-router-dom';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import AssignCell from '@components/students/assign_cell.jsx';
import { setUploadFilters } from '~/app/assets/javascripts/actions/uploads_actions';
import { fetchUserRevisions } from '~/app/assets/javascripts/actions/user_revisions_actions';
import { fetchTrainingStatus } from '~/app/assets/javascripts/actions/training_status_actions';
import { groupByAssignmentType } from '@components/util/helpers';
import { trunc } from '~/app/assets/javascripts/utils/strings';

// Actions
import {
  fetchTrainingModuleExercisesByUser
} from '~/app/assets/javascripts/actions/exercises_actions';

const Student = createReactClass({
  displayName: 'Student',

  propTypes: {
    assignments: PropTypes.array,
    course: PropTypes.object.isRequired,
    current_user: PropTypes.object,
    editable: PropTypes.bool,
    fetchUserRevisions: PropTypes.func.isRequired,
    fetchTrainingStatus: PropTypes.func.isRequired,
    isOpen: PropTypes.bool,
    minimalView: PropTypes.bool,
    student: PropTypes.object.isRequired,
    toggleDrawer: PropTypes.func,
    wikidataLabels: PropTypes.object
  },

  setUploadFilters(selectedFilters) {
    this.props.setUploadFilters(selectedFilters);
  },

  stop(e) {
    return e.stopPropagation();
  },

  openDrawer() {
    if (!this.props.isOpen) {
      const { course, student } = this.props;
      this.props.fetchUserRevisions(course.id, student.id);
      this.props.fetchTrainingStatus(student.id, course.id);
      this.props.fetchExercises(course.id, student.id);
    }
    return this.props.toggleDrawer(`drawer_${this.props.student.id}`);
  },

  _shouldShowRealName() {
    const studentRole = 0;
    if (!this.props.student.real_name) { return false; }
    return this.props.current_user && (this.props.current_user.admin || this.props.current_user.role > studentRole);
  },

  render() {
    const {
      isOpen, student
    } = this.props;

    let className = 'students-exercise students';
    className += isOpen ? ' open' : '';

    const userName = this._shouldShowRealName() ? (
      <span>
        <strong>{trunc(student.real_name)}</strong>
        &nbsp;
        (
        <a href={`/users/${student.username}`}>
          {trunc(student.username)}
        </a>)
      </span>
    )
      : (
        <span>
          <a href={`/users/${student.username}`}>
            {trunc(student.username)}
          </a>
        </span>
      );

    const {
      course_exercise_progress_assigned_count: exercise_assigned,
      course_exercise_progress_completed_count: exercise_completed,
      course_training_progress_assigned_count: training_assigned,
      course_training_progress_completed_count: training_completed
    } = student;
    const exerciseProgress = student.course_exercise_progress_description ? (
      <small className={exercise_assigned === exercise_completed ? 'modules-complete' : 'red'}>
        {student.course_exercise_progress_description}
      </small>
    ) : undefined;

    const trainingProgress = student.course_training_progress_description ? (
      <small className={training_assigned === training_completed ? 'modules-complete' : 'red'}>
        {student.course_training_progress_description}
      </small>
    ) : undefined;

    return (
      <tr onClick={this.openDrawer} className={className}>
        <td>
          <div className="name">
            {userName}
          </div>
          <div className="sandbox-link">
            <a onClick={this.stop} href={student.sandbox_url} target="_blank">{I18n.t('users.sandboxes')}</a>
            &nbsp;
            <a onClick={this.stop} href={student.contribution_url} target="_blank">{I18n.t('users.edits')}</a>
          </div>
        </td>
        <td className="desktop-only-tc">
          {exerciseProgress}
        </td>
        <td className="desktop-only-tc">
          {trainingProgress}
        </td>
        <td><button className="icon icon-arrow table-expandable-indicator" /></td>
      </tr>
    );
  }
}
);

const mapDispatchToProps = {
  setUploadFilters,
  fetchUserRevisions,
  fetchTrainingStatus,
  fetchExercises: fetchTrainingModuleExercisesByUser
};

export default connect(null, mapDispatchToProps)(Student);
