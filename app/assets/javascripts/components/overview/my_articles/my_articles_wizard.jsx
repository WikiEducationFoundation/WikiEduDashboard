import React from 'react';
import { connect } from 'react-redux';
import { ReviewerLink } from './helpers';

import { fetchAssignments, updateAssignmentStatus } from '../../../actions/assignment_actions';
import assignmentContent from './step_processes/assignments';

const StepNumber = ({ index }) => (
  <span className="step-number">{index + 1}</span>
);

const Title = ({ title }) => (
  <h3 className="step-title">{ title }</h3>
);

const Description = ({ content }) => (
  <p className="step-description">{ content }</p>
);

const Links = ({ trainings }) => {
  const links = trainings.map((training, index) => (
    <a key={index} href={`../../${training.path}`}>{training.title}</a>
  ));

  return (
    <aside className="step-links">
      { links }
    </aside>
  );
};

const Reviewers = ({ reviewers }) => {
  if (!reviewers) return null;

  return (
    <section className="step-members">
      <ReviewerLink reviewers={reviewers} />
    </section>
  );
};

const ButtonNavigation = ({
  active, assignment, courseSlug, index, last,
  handleUpdateAssignment, refreshAssignments // functions
}) => {
  const update = (undo = false) => async () => {
    const {
      assignment_all_statuses: statuses,
      assignment_status: status
    } = assignment;
    const i = statuses.indexOf(status);
    const updated = (undo ? statuses[i - 1] : statuses[i + 1]) || status;

    await handleUpdateAssignment(assignment, updated);
    await refreshAssignments(courseSlug);
  };

  return (
    <nav className="step-navigation">
      {
        index ? (
          <button
            className="button small"
            disabled={!active}
            onClick={update('undo')}
          >
            &laquo; Go Back a Step
          </button>
        ) : null
      }
      {
        last ? null : (
          <button
            className="button dark small"
            disabled={!active}
            onClick={update()}
          >
            Mark Complete &raquo;
          </button>
        )
      }
    </nav>
  );
};

// Step Components
const Step = ({
  assignment, content, courseSlug, index, status, title, trainings, last = false,
  handleUpdateAssignment, refreshAssignments
}) => {
  const active = assignment.assignment_status === status;
  return (
    <article className={`step ${active ? 'active' : ''}`}>
      <StepNumber index={index} />
      <Title title={title} />
      <Description content={content} />
      <Links trainings={trainings} />
      { status === 'ready_for_review' && <Reviewers reviewers={assignment.reviewers} /> }
      <ButtonNavigation
        active={active}
        assignment={assignment}
        courseSlug={courseSlug}
        index={index}
        last={last}
        handleUpdateAssignment={handleUpdateAssignment}
        refreshAssignments={refreshAssignments}
      />
    </article>
  );
};

export const Wizard = ({ assignment, courseSlug, handleUpdateAssignment, refreshAssignments }) => {
  const steps = assignmentContent.map((content, index, { length }) => (
    <Step
      {...content}
      assignment={assignment}
      courseSlug={courseSlug}
      index={index}
      key={index}
      last={index === length - 1}
      handleUpdateAssignment={handleUpdateAssignment}
      refreshAssignments={refreshAssignments}
    />
  ));

  return (
    <section className="flow">
      { steps }
    </section>
  );
};

const mapDispatchToProps = {
  handleUpdateAssignment: updateAssignmentStatus,
  refreshAssignments: fetchAssignments
};

export default connect(null, mapDispatchToProps)(Wizard);
