import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import { useDispatch, connect } from 'react-redux';
import { setUploadFilters } from '~/app/assets/javascripts/actions/uploads_actions';
import { fetchUserRevisions } from '~/app/assets/javascripts/actions/user_revisions_actions';
import { fetchTrainingStatus } from '~/app/assets/javascripts/actions/training_status_actions';
import { fetchTrainingModuleExercisesByUser } from '~/app/assets/javascripts/actions/exercises_actions';
import ExerciseProgressDescription from './ExerciseProgressDescription.jsx';
import TrainingProgressDescription from './TrainingProgressDescription.jsx';

const Student = (props) => {
  const [isOpenState, setIsOpenState] = useState(props.isOpen);
  const dispatch = useDispatch();

  useEffect(() => {
    setIsOpenState(props.isOpen);
  }, [props.isOpen]);

  const openDrawer = () => {
    if (!isOpenState) {
      dispatch(fetchUserRevisions(props.course.id, props.student.id));
      dispatch(fetchTrainingStatus(props.student.id, props.course.id));
      dispatch(fetchTrainingModuleExercisesByUser(props.course.id, props.student.id));
      props.toggleDrawer(`drawer_${props.student.id}`);
    }
  };
  setUploadFilters = (selectedFilters) => {
    props.setUploadFilters(selectedFilters);
  };
  const stop = (e) => {
    e.stopPropagation();
  };

  let className = 'students-exercise students';
  className += isOpenState ? ' open' : '';

  return (
    <tr onClick={openDrawer} className={className}>
      <td className="desktop-only-tc">
        <ExerciseProgressDescription student={props.student} />
      </td>
      <td className="desktop-only-tc">
        <TrainingProgressDescription student={props.student} />
      </td>
      <td className="table-action-cell">
        <button className="icon icon-arrow-toggle table-expandable-indicator" onClick={stop} />
      </td>
    </tr>
  );
};

Student.propTypes = {
  assignments: PropTypes.array,
  course: PropTypes.object.isRequired,
  current_user: PropTypes.object,
  editable: PropTypes.bool,
  isOpen: PropTypes.bool,
  minimalView: PropTypes.bool,
  student: PropTypes.object.isRequired,
  toggleDrawer: PropTypes.func,
  wikidataLabels: PropTypes.object,
};
const mapDispatchToProps = {
  setUploadFilters,
};
export default connect(null, mapDispatchToProps)(Student);
