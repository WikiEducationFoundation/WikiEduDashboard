import React from 'react';
import { connect } from 'react-redux';
import { HashLink as Link } from 'react-router-hash-link';
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

const Links = ({ courseSlug, trainings }) => {
  const links = trainings.map((training, index) => {
    return training.external
    ? <a key={index} href={training.path} target="_blank">{training.title}</a>
    : (
      <Link
        key={index}
        to={`/courses/${courseSlug}/${training.path}`}
        scroll={el => el.scrollIntoView({ block: 'center' })}
      >
        {training.title}
      </Link>
    );
  });

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
  active, assignment, courseSlug, index,
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
      <button
        className="button dark small"
        disabled={!active}
        onClick={update()}
      >
        Mark Complete &raquo;
      </button>
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
    <article aria-label={active ? 'Current step' : ''} className={`step ${active ? 'active' : ''}`}>
      <StepNumber index={index} />
      <Title title={title} />
      <Description content={content} />
      <Links courseSlug={courseSlug} trainings={trainings} />
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

export class Wizard extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      show: false
    };

    this.toggle = this.toggle.bind(this);
  }

  toggle() {
    this.setState({ show: !this.state.show });
  }

  render() {
    const {
      assignment, courseSlug,
      handleUpdateAssignment, refreshAssignments
    } = this.props;
    const { show } = this.state;

    const steps = assignmentContent(assignment).map((content, index) => (
      <Step
        {...content}
        assignment={assignment}
        courseSlug={courseSlug}
        index={index}
        key={index}
        handleUpdateAssignment={handleUpdateAssignment}
        refreshAssignments={refreshAssignments}
      />
    ));
    const lis = assignmentContent(assignment).map(({ status, title }, i) => {
      const selected = assignment.assignment_status === status;
      return (
        <li className={selected ? 'selected' : ''} key={`process-step-${i}`}>
          {`${i + 1}. ${title}`}
        </li>
      );
    });

    return (
      <>
        <section className={`flow${show ? '' : ' hidden'}`}>
          {steps}
        </section>
        <nav className="toggle-wizard" onClick={this.toggle}>
          <ul>
            { lis }
            {
              show
              ? <li aria-label="Close Progress Tracker" className="icon icon-arrow-reverse table-expandable-indicator" />
              : <li aria-label="Show Progress Tracker" className="icon icon-arrow table-expandable-indicator" />
            }
          </ul>
        </nav>
      </>
    );
  }
}

const mapDispatchToProps = {
  handleUpdateAssignment: updateAssignmentStatus,
  refreshAssignments: fetchAssignments
};

export default connect(null, mapDispatchToProps)(Wizard);
