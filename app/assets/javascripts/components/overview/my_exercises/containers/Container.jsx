import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { NavLink } from 'react-router-dom';

// Components
import UpcomingExercise from '../components/UpcomingExercise.jsx';

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
    if (exercises.loading) {
      return (
        <div className="module my-exercises">
          <h3>Loading...</h3>
        </div>
      );
    }

    const incomplete = exercises.unread.concat(exercises.incomplete);
    const [latest, ...remaining] = [...incomplete].sort((a, b) => a.block_id > b.block_id);

    if (!latest) {
      return (
        <div className="module my-exercises">
          <h3>All exercises completed.</h3>
        </div>
      );
    }

    return (
      <div className="module my-exercises">
        <header className="header">
          <h3>
          Upcoming Exercises
            {
              remaining.length
              ? <small>{ remaining.length } additional exercises remaining.</small>
              : null
            }
          </h3>
          <NavLink to={`../../${course.slug}/resources`} className="resources-link">
            See your remaining exercises
          </NavLink>
        </header>
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
