import React from 'react';
import PropTypes from 'prop-types';
import processes from '@components/overview/my_articles/step_processes';

// components
import Step from './Step/Step.jsx';
import NavigationElements from './NavigationElements/NavigationElements';

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
    const { assignment, course } = this.props;
    const { show } = this.state;

    const steps = processes(assignment, course).map((content, index) => (
      <Step
        {...content}
        assignment={assignment}
        course={course}
        index={index}
        key={index}
      />
    ));

    return (
      <div className="progress-tracker">
        <button
          className="screen-reader"
          onClick={this.toggle}
        >
          Click to hide or show progress tracker
        </button>
        <nav
          aria-label="Click to hide or show progress tracker"
          className="toggle-progress-tracker"
          onClick={this.toggle}
        >
          <NavigationElements assignment={assignment} show={show} course={course} />
        </nav>
        <section className="flow">
          {show ? steps : null}
        </section>
      </div>
    );
  }
}

ProgressTracker.propTypes = {
  // props
  assignment: PropTypes.object.isRequired,
  course: PropTypes.object.isRequired,
};

export default ProgressTracker;
