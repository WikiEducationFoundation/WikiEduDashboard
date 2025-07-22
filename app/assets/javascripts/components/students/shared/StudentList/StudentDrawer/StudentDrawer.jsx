import React, { useState } from 'react';
import PropTypes from 'prop-types';

// Components
import Contributions from './Contributions';
import TrainingStatus from './TrainingStatus/TrainingStatus';

export const StudentDrawer = ({
  course, exerciseView, isOpen, revisions = [],
  student, trainingModules = [], wikidataLabels
}) => {
  const [selectedIndex, setSelectedIndex] = useState(-1);

  const showDiff = (index) => {
    setSelectedIndex(index);
  };
  return (
    <tr className="drawer" style={{ display: isOpen ? 'table-row' : 'none' }}>
      <td colSpan="7">
        {
          exerciseView
            ? (
              <Contributions
                course={course}
                revisions={revisions}
                selectedIndex={selectedIndex}
                showDiff={showDiff}
                student={student}
                wikidataLabels={wikidataLabels}
              />
            ) : <TrainingStatus trainingModules={trainingModules} />
        }
      </td>
    </tr>
  );
};

StudentDrawer.propTypes = {
  course: PropTypes.object,
  exerciseView: PropTypes.bool,
  student: PropTypes.object,
  isOpen: PropTypes.bool,
  revisions: PropTypes.array,
  trainingModules: PropTypes.array,
  wikidataLabels: PropTypes.object
};

export default (StudentDrawer);
