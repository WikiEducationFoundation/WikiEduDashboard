import React from "react";
import { Link, useNavigate } from "react-router-dom";
import { connect } from "react-redux";
import PropTypes from "prop-types";
import AssignCell from "@components/common/AssignCell/AssignCell.jsx";
import { setUploadFilters } from "~/app/assets/javascripts/actions/uploads_actions";
import { fetchUserRevisions } from "~/app/assets/javascripts/actions/user_revisions_actions";
import { fetchTrainingStatus } from "~/app/assets/javascripts/actions/training_status_actions";
import { groupByAssignmentType } from "@components/util/helpers";
import { ASSIGNED_ROLE, REVIEWING_ROLE } from "@constants/assignments";

// Components
import ContentAdded from "./ContentAdded";
import StudentUsername from "./StudentUsername";
import ExerciseProgressDescription from "@components/students/components/Articles/SelectedStudent/ExercisesList/StudentExercise/ExerciseProgressDescription.jsx";
import TrainingProgressDescription from "@components/students/components/Articles/SelectedStudent/ExercisesList/StudentExercise/TrainingProgressDescription.jsx";

// Actions
import { fetchTrainingModuleExercisesByUser } from "~/app/assets/javascripts/actions/exercises_actions";

const Student = ({
  assignments,
  course,
  current_user,
  editable,
  fetchUserRevisions,
  fetchTrainingStatus,
  minimalView,
  student,
  showRecent,
  setUploadFilters,
}) => {
  const navigate = useNavigate();

  const handleClick = (e) => {
    e.stopPropagation();
  };

  const openStudentDetails = () => {
    const url = `/courses/${course.slug}/students/articles/${encodeURIComponent(
      student.username
    )}`;
    navigate(url);
  };

  const shouldShowRealName = () => {
    return student.real_name && current_user.isAdvancedRole;
  };

  let recentRevisions;
  if (showRecent) {
    recentRevisions = (
      <td className="desktop-only-tc" onClick={openStudentDetails}>
        {student.recent_revisions}
      </td>
    );
  }

  let assignButton;
  let reviewButton;
  if (assignments && course.published) {
    const { assigned, reviewing, unassigned, reviewable } =
      groupByAssignmentType(assignments, student.id);

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
      <td onClick={openStudentDetails} style={{ minWidth: "250px" }}>
        <div className="name">
          <StudentUsername current_user={current_user} student={student} />
        </div>
        <div className="sandbox-link">
          <a
            onClick={handleClick}
            href={student.sandbox_url}
            target="_blank"
            rel="noopener noreferrer"
          >
            {I18n.t("users.sandboxes")}
          </a>
          &nbsp;
          <a
            onClick={handleClick}
            href={student.contribution_url}
            target="_blank"
            rel="noopener noreferrer"
          >
            {I18n.t("users.edits")}
          </a>
        </div>
        <ExerciseProgressDescription student={student} />
        <TrainingProgressDescription student={student} />
      </td>
      <td className="desktop-only-tc" onClick={openStudentDetails}>
        {assignButton}
      </td>
      <td className="desktop-only-tc" onClick={openStudentDetails}>
        {reviewButton}
      </td>
      {recentRevisions}
      <td className="desktop-only-tc" onClick={openStudentDetails}>
        <ContentAdded course={course} student={student} />
      </td>
      <td className="desktop-only-tc" onClick={openStudentDetails}>
        {student.references_count}
      </td>
      <td className="desktop-only-tc">
        <Link
          to={uploadsLink}
          onClick={() =>
            setUploadFilters([
              { value: student.username, label: student.username },
            ])
          }
        >
          {student.total_uploads || 0}
        </Link>
      </td>
    </tr>
  );
};

Student.propTypes = {
  assignments: PropTypes.array,
  course: PropTypes.object.isRequired,
  current_user: PropTypes.object,
  editable: PropTypes.bool,
  fetchUserRevisions: PropTypes.func.isRequired,
  fetchTrainingStatus: PropTypes.func.isRequired,
  minimalView: PropTypes.bool,
  student: PropTypes.object.isRequired,
  setUploadFilters: PropTypes.func.isRequired,
  showRecent: PropTypes.bool,
};

const mapDispatchToProps = {
  setUploadFilters,
  fetchUserRevisions,
  fetchTrainingStatus,
  fetchExercises: fetchTrainingModuleExercisesByUser,
};

export default connect(null, mapDispatchToProps)(Student);
