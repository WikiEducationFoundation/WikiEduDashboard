import React from 'react';
import createReactClass from 'create-react-class';
import { withRouter } from 'react-router';
import { Link } from 'react-router-dom';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import AssignCell from '@components/common/AssignCell/AssignCell.jsx';
import { setUploadFilters } from '~/app/assets/javascripts/actions/uploads_actions';
import { fetchUserRevisions } from '~/app/assets/javascripts/actions/user_revisions_actions';
import { fetchTrainingStatus } from '~/app/assets/javascripts/actions/training_status_actions';
import { groupByAssignmentType } from '@components/util/helpers';

// Components
import ContentAdded from './ContentAdded';
import StudentUsername from './StudentUsername';
import ExerciseProgressDescription from '@components/students/components/Articles/SelectedStudent/ExercisesList/StudentExercise/ExerciseProgressDescription.jsx';
import TrainingProgressDescription from '@components/students/components/Articles/SelectedStudent/ExercisesList/StudentExercise/TrainingProgressDescription.jsx';

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
    const { course, history, isOpen, student, toggleDrawer } = this.props;
    if (!toggleDrawer) {
      const url = `/courses/${course.slug}/students/articles/${student.username}`;
      return history.push(url);
    }

    if (!isOpen) {
      this.props.fetchUserRevisions(course.id, student.id);
      this.props.fetchTrainingStatus(student.id, course.id);
      this.props.fetchExercises(course.id, student.id);
    }

    return toggleDrawer(`drawer_${student.id}`);
  },

  _shouldShowRealName() {
    const studentRole = 0;
    if (!this.props.student.real_name) { return false; }
    return this.props.current_user && (this.props.current_user.admin || this.props.current_user.role > studentRole);
  },

  render() {
    const {
      assignments, course, current_user, editable, isOpen,
      showRecent, student, wikidataLabels
    } = this.props;

    let className = 'students';
    className += isOpen ? ' open' : '';

    let recentRevisions;
    if (showRecent) {
      recentRevisions = (
        <td className="desktop-only-tc" onClick={this.openDrawer} >
          {student.recent_revisions}
        </td>
      );
    }

    let assignButton;
    let reviewButton;
    if (assignments && course.published) {
      const {
        assigned, reviewing,
        unassigned, reviewable
      } = groupByAssignmentType(assignments, student.id);

      assignButton = (
        <AssignCell
          assignments={assigned}
          assignmentsLength={assigned.length}
          course={course}
          current_user={current_user}
          editable={editable}
          isStudentsPage
          student={student}
          role={0}
          wikidataLabels={wikidataLabels}
          unassigned={unassigned}
        />
      );

      reviewButton = (
        <AssignCell
          assignments={reviewing}
          assignmentsLength={reviewing.length}
          course={course}
          current_user={current_user}
          editable={editable}
          isStudentsPage
          student={student}
          role={1}
          wikidataLabels={wikidataLabels}
          unassigned={reviewable}
        />
      );
    }

    const uploadsLink = `/courses/${course.slug}/uploads`;

    return (
      <tr className={className}>
        <td onClick={this.openDrawer} style={{ minWidth: '250px' }}>
          <div className="name">
            <StudentUsername current_user={current_user} student={student} />
          </div>
          <div className="sandbox-link">
            <a onClick={this.stop} href={student.sandbox_url} target="_blank">{I18n.t('users.sandboxes')}</a>
            &nbsp;
            <a onClick={this.stop} href={student.contribution_url} target="_blank">{I18n.t('users.edits')}</a>
          </div>
          <ExerciseProgressDescription student={student} />
          <TrainingProgressDescription student={student} />
        </td>
        <td className="desktop-only-tc" onClick={this.openDrawer}>
          {assignButton}
        </td>
        <td className="desktop-only-tc" onClick={this.openDrawer}>
          {reviewButton}
        </td>
        {recentRevisions}
        <ContentAdded course={course} student={student} />
        <td className="desktop-only-tc" onClick={this.openDrawer}>
          {student.references_count}
        </td>
        <td className="desktop-only-tc">
          <Link
            to={uploadsLink}
            onClick={() => {
              this.setUploadFilters([{ value: student.username, label: student.username }]);
            }}
          >
            {student.total_uploads || 0}
          </Link>
        </td>
        {
          this.props.toggleDrawer && (
            <td onClick={this.openDrawer}>
              <button className="icon icon-arrow table-expandable-indicator" />
            </td>
          )
        }
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

const component = withRouter(Student);
export default connect(null, mapDispatchToProps)(component);
