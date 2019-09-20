import React from 'react';
import PropTypes from 'prop-types';
import assignmentContent from '../../../../../step_processes/assignments';

// components
import Step from './Step';
import NavigationElements from './NavigationElements';

export class ProgressTracker extends React.Component {
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

    return (
      <>
        <section className={`flow${show ? '' : ' hidden'}`}>
          { steps }
        </section>
        <nav className="toggle-wizard" onClick={this.toggle}>
          <NavigationElements assignment={assignment} show={show} />
        </nav>
      </>
    );
  }
}

ProgressTracker.propTypes = {
  // props
  assignment: PropTypes.object.isRequired,
  course: PropTypes.object.isRequired,

  // actions
  updateAssignmentStatus: PropTypes.func.isRequired,
  fetchAssignments: PropTypes.func.isRequired
};

export default ProgressTracker;
