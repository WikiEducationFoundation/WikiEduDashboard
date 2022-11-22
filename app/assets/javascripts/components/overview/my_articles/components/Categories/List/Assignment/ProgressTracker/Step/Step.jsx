import React from 'react';
import PropTypes from 'prop-types';

// components
import StepNumber from './StepNumber';
import Title from './Title';
import Description from './Description.jsx';
import Links from './Links.jsx';
import Reviewers from './Reviewers.jsx';
import ButtonNavigation from './ButtonNavigation.jsx';

export const Step = ({
  assignment, content, course, index, status, title, trainings, buttonLabel, stepAction, last = false,
  updateAssignmentStatus, fetchAssignments, dispatch
}) => {
  const active = assignment.assignment_status === status;
  return (
    <article aria-label={active ? 'Current step' : ''} className={`step ${active ? 'active' : ''}`}>
      <StepNumber index={index} />
      <Title title={title} />
      <Description content={content} />
      <Links courseSlug={course.slug} trainings={trainings} />
      {status === 'ready_for_review' && <Reviewers assignment={assignment} />}
      <ButtonNavigation
        active={active}
        assignment={assignment}
        course={course}
        index={index}
        last={last}
        updateAssignmentStatus={updateAssignmentStatus}
        fetchAssignments={fetchAssignments}
        buttonLabel={buttonLabel}
        stepAction={stepAction}
        dispatch={dispatch}
      />
    </article>
  );
};

Step.propTypes = {
  // props
  assignment: PropTypes.object.isRequired,
  content: PropTypes.string.isRequired,
  course: PropTypes.object.isRequired,
  index: PropTypes.number.isRequired,
  status: PropTypes.string.isRequired,
  title: PropTypes.string.isRequired,
  trainings: PropTypes.array.isRequired,

  // actions
  updateAssignmentStatus: PropTypes.func.isRequired,
  fetchAssignments: PropTypes.func.isRequired,
};

export default Step;
