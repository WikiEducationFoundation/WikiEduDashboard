import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';

// Components
import UpcomingExercise from '../components/UpcomingExercise.jsx';
import Header from '../components/Header.jsx';

// Actions
import {
  fetchTrainingModuleExercisesByUser
} from '~/app/assets/javascripts/actions/exercises_actions';

export class MyExercisesContainer extends React.Component {
  componentDidMount() {
    return this.props.fetchTrainingModuleExercisesByUser(this.props.course.id);
  }

  render() {
    const { course, exercises, trainingLibrarySlug } = this.props;
    const incomplete = exercises.unread.concat(exercises.incomplete);
    if (!incomplete.length) return null;
    if (exercises.loading) {
      return (
        <div className="module my-exercises">
          <h3>Loading...</h3>
        </div>
      );
    }

    const [latest, ...remaining] = [...incomplete].sort((a, b) => a.block_id > b.block_id);
    if (!latest) {
      return (
        <div className="module my-exercises">
          <Header completed={true} course={course} text="Completed all exercises" />
        </div>
      );
    }

    return (
      <div className="module my-exercises">
        <Header course={course} remaining={remaining} text="Upcoming Exercises" />
        <UpcomingExercise exercise={latest} trainingLibrarySlug={trainingLibrarySlug} />
      </div>
    );
  }
}

MyExercisesContainer.propTypes = {
  exercises: PropTypes.object.isRequired,
  course: PropTypes.object.isRequired,
  trainingLibrarySlug: PropTypes.string.isRequired
};

const mapStateToProps = ({ course, exercises }) => ({ course, exercises });

const mapDispatchToProps = {
  fetchTrainingModuleExercisesByUser
};

export default connect(mapStateToProps, mapDispatchToProps)(MyExercisesContainer);
