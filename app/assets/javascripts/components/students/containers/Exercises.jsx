import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';

// Components
import StudentsSubNavigation from '@components/students/components/StudentsSubNavigation.jsx';
import Controls from '@components/students/components/Overview/Controls/Controls.jsx';
import StudentExercisesList from '../components/Articles/SelectedStudent/ExercisesList/StudentExercisesList';

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
      course, current_user, prefix, openKey, sort, students,
      trainingStatus, wikidataLabels, sortUsers,
      notify, sortSelect
    } = this.props;

    return (
      <div className="list__wrapper">
        <StudentsSubNavigation
          course={course}
          heading={I18n.t('instructor_view.exercises_and_trainings', { prefix })}
        />
        {
          current_user.isAdvancedRole
            ? (
              <Controls
                course={course}
                current_user={current_user}
                students={students}
                notify={notify}
                showOverviewFilters={false}
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
  course: PropTypes.object.isRequired,
  current_user: PropTypes.object.isRequired,
  prefix: PropTypes.string.isRequired,
  openKey: PropTypes.string,
  students: PropTypes.array,
  wikidataLabels: PropTypes.object,

  sort: PropTypes.object.isRequired,
  sortSelect: PropTypes.func.isRequired,
  sortUsers: PropTypes.func.isRequired,
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
