import React from 'react';
import createReactClass from 'create-react-class';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import { setUploadFilters } from '~/app/assets/javascripts/actions/uploads_actions';
import { fetchUserRevisions } from '~/app/assets/javascripts/actions/user_revisions_actions';
import { fetchTrainingStatus } from '~/app/assets/javascripts/actions/training_status_actions';

// Components
import ExerciseProgressDescription from './ExerciseProgressDescription.jsx';
import TrainingProgressDescription from './TrainingProgressDescription.jsx';

// Actions
import {
  fetchTrainingModuleExercisesByUser
} from '~/app/assets/javascripts/actions/exercises_actions';

const Student = createReactClass({
  displayName: 'Student',

  propTypes: {
    assignments: PropTypes.array,
    course: PropTypes.object.isRequired,
    current_user: PropTypes.object,
    editable: PropTypes.bool,
    fetchUserRevisions: PropTypes.func.isRequired,
    fetchTrainingStatus: PropTypes.func.isRequired,
    isOpen: PropTypes.bool,
    minimalView: PropTypes.bool,
    student: PropTypes.object.isRequired,
    toggleDrawer: PropTypes.func,
    wikidataLabels: PropTypes.object
  },

  setUploadFilters(selectedFilters) {
    this.props.setUploadFilters(selectedFilters);
  },

  stop(e) {
    return e.stopPropagation();
  },

  openDrawer() {
    if (!this.props.isOpen) {
      const { course, student } = this.props;
      this.props.fetchUserRevisions(course.id, student.id);
      this.props.fetchTrainingStatus(student.id, course.id);
      this.props.fetchExercises(course.id, student.id);
    }
    return this.props.toggleDrawer(`drawer_${this.props.student.id}`);
  },

  render() {
    const {
      isOpen, student
    } = this.props;

    let className = 'students-exercise students';
    className += isOpen ? ' open' : '';

    return (
      <tr onClick={this.openDrawer} className={className}>
        <td className="desktop-only-tc">
          <ExerciseProgressDescription student={student} />
        </td>
        <td className="desktop-only-tc">
          <TrainingProgressDescription student={student} />
        </td>
        <td className="table-action-cell"><button className="icon icon-arrow-toggle table-expandable-indicator" /></td>
      </tr>
    );
  }
}
);

const mapDispatchToProps = {
  setUploadFilters,
  fetchUserRevisions,
  fetchTrainingStatus,
  fetchExercises: fetchTrainingModuleExercisesByUser
};

export default connect(null, mapDispatchToProps)(Student);
