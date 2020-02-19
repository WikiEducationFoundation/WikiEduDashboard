import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';

// Components
import Contributions from './Contributions';
import TrainingStatus from './TrainingStatus/TrainingStatus';

export class StudentDrawer extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      selectedIndex: -1,
    };
  }

  shouldComponentUpdate(nextProps) {
    return !!(nextProps.isOpen || this.props.isOpen);
  }

  showDiff(index) {
    this.setState({ selectedIndex: index });
  }

  render() {
    const {
      course, exercises, exerciseView, isOpen, revisions = [],
      student, trainingModules = [], wikidataLabels
    } = this.props;

    if (!isOpen) return <tr />;

    return (
      <tr className="drawer">
        <td colSpan="7">
          {
            exerciseView
            ? (
              <Contributions
                course={course}
                revisions={revisions}
                selectedIndex={this.state.selectedIndex}
                showDiff={this.showDiff}
                student={student}
                wikidataLabels={wikidataLabels}
              />
            ) : <TrainingStatus exercises={exercises} trainingModules={trainingModules} />
          }
        </td>
      </tr>
    );
  }
}

StudentDrawer.propTypes = {
  course: PropTypes.object,
  exerciseView: PropTypes.bool,
  student: PropTypes.object,
  isOpen: PropTypes.bool,
  revisions: PropTypes.array,
  trainingModules: PropTypes.array,
  wikidataLabels: PropTypes.object
};

const mapStateToProps = ({ exercises }) => ({ exercises });

const mapDispatchToProps = null;

export default connect(mapStateToProps, mapDispatchToProps)(StudentDrawer);
