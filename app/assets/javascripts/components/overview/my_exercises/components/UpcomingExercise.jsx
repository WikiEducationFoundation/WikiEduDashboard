import React from 'react';
import PropTypes from 'prop-types';

// Components
import ModuleRow from '@components/timeline/TrainingModules/ModuleRow/ModuleRow.jsx';

export const UpcomingExercise = ({ exercise, trainingLibrarySlug }) => (
  <table className="table">
    <tbody>
      <ModuleRow
        key={exercise.id}
        module={exercise}
        trainingLibrarySlug={trainingLibrarySlug}
      />
    </tbody>
  </table>
);

UpcomingExercise.propTypes = {
  exercise: PropTypes.object.isRequired
};

export default UpcomingExercise;
