import React from 'react';
import createReactClass from 'create-react-class';
import withRouter from '../../../../util/withRouter';
import { Link } from 'react-router-dom';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import AssignCell from '@components/common/AssignCell/AssignCell.jsx';
import { setUploadFilters } from '~/app/assets/javascripts/actions/uploads_actions';
import { fetchTrainingStatus } from '~/app/assets/javascripts/actions/training_status_actions';
import { groupByAssignmentType } from '@components/util/helpers';
import { ASSIGNED_ROLE, REVIEWING_ROLE } from '@constants/assignments';

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
    fetchTrainingStatus: PropTypes.func.isRequired,
    minimalView: PropTypes.bool,
    student: PropTypes.object.isRequired,
    openStudentDetailsView: PropTypes.func.isRequired
  },

  setUploadFilters(selectedFilters) {
    this.props.setUploadFilters(selectedFilters);
  },

  stop(e) {
    return e.stopPropagation();
  },

  openStudentDetailsView() {
    const { course, student, openStudentDetailsView } = this.props;
    openStudentDetailsView(course.slug, student.username);
  },

  _shouldShowRealName() {
    if (!this.props.student.real_name) { return false; }
    return this.props.current_user.isAdvancedRole;
  },

  render() {
    const {
      assignments, course, current_user, editable,
      showRecent, student
    } = this.props;

    let recentRevisions;
    if (showRecent) {
      recentRevisions = (
        <td className="desktop-only-tc" onClick={this.openStudentDetailsView} >
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
          role={ASSIGNED_ROLE}
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
          role={REVIEWING_ROLE}
          unassigned={reviewable}
        />
      );
    }

    const uploadsLink = `/courses/${course.slug}/uploads`;

    return (
      <tr className="students">
        <td onClick={this.openStudentDetailsView} style={{ minWidth: '250px' }}>
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
        <td className="desktop-only-tc" onClick={this.openStudentDetailsView}>
          {assignButton}
        </td>
        <td className="desktop-only-tc" onClick={this.openStudentDetailsView}>
          {reviewButton}
        </td>
        {recentRevisions}
        <td className="desktop-only-tc" onClick={this.openStudentDetailsView}>
          <ContentAdded course={course} student={student} />
        </td>
        <td className="desktop-only-tc" onClick={this.openStudentDetailsView}>
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
      </tr>
    );
  }
}
);

const mapDispatchToProps = {
  setUploadFilters,
  fetchTrainingStatus,
  fetchExercises: fetchTrainingModuleExercisesByUser
};

const component = withRouter(Student);
export default connect(null, mapDispatchToProps)(component);
