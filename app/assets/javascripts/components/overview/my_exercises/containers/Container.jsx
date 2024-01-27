import React, { useEffect } from 'react';
import PropTypes from 'prop-types';
import { useDispatch, useSelector } from 'react-redux';

// Components
import UpcomingExercise from '../components/UpcomingExercise.jsx';
import Header from '../components/Header.jsx';

// Actions
import {
  fetchTrainingModuleExercisesByUser
} from '~/app/assets/javascripts/actions/exercises_actions';

const MyExercisesContainer = ({ trainingLibrarySlug }) => {
  const dispatch = useDispatch();

  const exercises = useSelector(state => state.exercises);
  const course = useSelector(state => state.course);

  useEffect(() => {
    const fetchData = async () => {
      await dispatch(fetchTrainingModuleExercisesByUser(course.id));
    };
    fetchData();
  }, []);

  const incomplete = exercises.incomplete.concat(exercises.unread);
  if (!incomplete.length) return null;
  if (exercises.loading) {
    return (
      <div className="module my-exercises" style={{ marginTop: '55px' }}>
        <h3>Loading...</h3>
      </div>
    );
  }

  const [latest, ...remaining] = [...incomplete].sort((a, b) => {
    if (a.block_id === b.block_id) { return 0; }
    return a.block_id > b.block_id ? 1 : -1;
  });
  if (!latest) {
    return (
      <div className="module my-exercises" style={{ marginTop: '55px' }}>
        <Header completed={true} course={course} text="Completed all exercises" />
      </div>
    );
  }

  return (
    <div className="module my-exercises" style={{ marginTop: '55px' }}>
      <Header course={course} remaining={remaining} text="Upcoming Exercises" />
      <UpcomingExercise exercise={latest} trainingLibrarySlug={trainingLibrarySlug} />
    </div>
  );
};

MyExercisesContainer.propTypes = {
  trainingLibrarySlug: PropTypes.string.isRequired
};


export default (MyExercisesContainer);
