import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';

// Components
import Controls from '../components/Exercises/Controls/Controls.jsx';
import StudentExercisesList from '../components/Exercises/StudentExercisesList';

// Actions
import {
  fetchTrainingModuleExercisesByUser
} from '~/app/assets/javascripts/actions/exercises_actions';
import { toggleUI } from '~/app/assets/javascripts/actions';

// Selectors
import { getStudentUsers } from '~/app/assets/javascripts/selectors';

export class Exercises extends React.Component {
  render() {
    const {
      course, current_user, openKey, sort, students,
      trainingStatus, wikidataLabels, sortUsers,
      sortSelect
    } = this.props;

    return (
      <div className="list__wrapper">
        {
          current_user.isAdmin
            ? (
              <Controls
                course={course}
                current_user={current_user}
                students={students}
                sortSelect={sortSelect}
              />
            ) : null
        }

        <StudentExercisesList
          course={course}
          current_user={current_user}
          openKey={openKey}
          sort={sort}
          sortUsers={sortUsers}
          students={students}
          toggleUI={this.props.toggleUI}
          trainingStatus={trainingStatus}
          wikidataLabels={wikidataLabels}
        />
      </div>
    );
  }
}

Exercises.propTypes = {

};

const mapStateToProps = state => ({
  openKey: state.ui.openKey,
  students: getStudentUsers(state),
  sort: state.users.sort,
  trainingStatus: state.trainingStatus
});

const mapDispatchToProps = {
  fetchTrainingModuleExercisesByUser,
  toggleUI
};

export default connect(mapStateToProps, mapDispatchToProps)(Exercises);
