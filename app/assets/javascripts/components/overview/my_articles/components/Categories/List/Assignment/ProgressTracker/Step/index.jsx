import React from 'react';

// components
import StepNumber from './StepNumber';
import Title from './Title';
import Description from './Description.jsx';
import Links from './Links.jsx';
import Reviewers from './Reviewers.jsx';
import ButtonNavigation from './ButtonNavigation.jsx';

export default ({
  assignment, content, courseSlug, index, status, title, trainings, last = false,
  updateAssignmentStatus, fetchAssignments
}) => {
  const active = assignment.assignment_status === status;
  return (
    <article aria-label={active ? 'Current step' : ''} className={`step ${active ? 'active' : ''}`}>
      <StepNumber index={index} />
      <Title title={title} />
      <Description content={content} />
      <Links courseSlug={courseSlug} trainings={trainings} />
      {status === 'ready_for_review' && <Reviewers reviewers={assignment.reviewers} />}
      <ButtonNavigation
        active={active}
        assignment={assignment}
        courseSlug={courseSlug}
        index={index}
        last={last}
        updateAssignmentStatus={updateAssignmentStatus}
        fetchAssignments={fetchAssignments}
      />
    </article>
  );
};
