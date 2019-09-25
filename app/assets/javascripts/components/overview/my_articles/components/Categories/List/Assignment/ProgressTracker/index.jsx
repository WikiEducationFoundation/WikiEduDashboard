import React from 'react';
import PropTypes from 'prop-types';
import processes from '../../../../../step_processes';

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
      fetchAssignments, updateAssignmentStatus
    } = this.props;
    const { show } = this.state;

    const steps = processes(assignment).map((content, index) => (
      <Step
        {...content}
        assignment={assignment}
        courseSlug={course.slug}
        index={index}
        key={index}
        fetchAssignments={fetchAssignments}
        updateAssignmentStatus={updateAssignmentStatus}
      />
    ));

    return (
      <>
        <section className="flow">
          { show ? steps : null }
        </section>
        <nav className="toggle-progress-tracker" onClick={this.toggle}>
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
  fetchAssignments: PropTypes.func.isRequired,
  updateAssignmentStatus: PropTypes.func.isRequired,
};

export default ProgressTracker;
