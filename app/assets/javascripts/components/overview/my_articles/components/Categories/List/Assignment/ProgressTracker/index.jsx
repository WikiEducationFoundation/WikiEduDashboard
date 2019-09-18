import React from 'react';
import assignmentContent from '../../../../../step_processes/assignments';

// components
import Step from './Step';

export default class Wizard extends React.Component {
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
      assignment, course,
      updateAssignmentStatus, fetchAssignments
    } = this.props;
    const { show } = this.state;

    const steps = assignmentContent(assignment).map((content, index) => (
      <Step
        {...content}
        assignment={assignment}
        courseSlug={course.slug}
        index={index}
        key={index}
        updateAssignmentStatus={updateAssignmentStatus}
        fetchAssignments={fetchAssignments}
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
            {lis}
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
