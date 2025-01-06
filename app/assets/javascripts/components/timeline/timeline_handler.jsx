// Import necessary hooks (useState, useEffect) and useNavigate from react-router-dom
import React, { useEffect, useState } from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import TransitionGroup from '../common/css_transition_group';
import { Route, Routes } from 'react-router-dom';
import Timeline from './timeline.jsx';
// import Grading from './grading.jsx';
import CourseDateUtils from '../../utils/course_date_utils.js';
import Wizard from '../wizard/wizard.jsx';
import Meetings from './meetings.jsx';

import { fetchAllTrainingModules } from '../../actions/training_actions';

import {
  addWeek, deleteWeek, persistTimeline, setBlockEditable, cancelBlockEditable,
  updateBlock, addBlock, deleteBlock, insertBlock, updateTitle, resetTitles, restoreTimeline, deleteAllWeeks
} from '../../actions/timeline_actions';
import { getWeeksArray, getAllWeeksArray, getAvailableTrainingModules, editPermissions, getAllWeekDates } from '../../selectors';

// Define TimelineHandler as a functional component using an arrow function
// Move propTypes outside the component definition
// Replace state variables with useState hooks
const TimelineHandler = (props) => {
  const [reorderable, setReorderable] = useState(false);
  const [editableTitles, setEditableTitles] = useState(false);

// Replace componentDidMount with useEffect hook
  useEffect(() => {
    document.title = `${props.course.title} - ${I18n.t('courses.timeline_link')}`;
    props.fetchAllTrainingModules();
  }, [props.course.title, props.fetchAllTrainingModules]);

// Convert class methods to regular functions within the component
  const _cancelBlockEditable = (blockId) => {
    // TODO: Restore to persisted state for this block only
    props.cancelBlockEditable(blockId);
  };

  const _cancelGlobalChanges = () => {
    setReorderable(false);
    setEditableTitles(false);
    props.restoreTimeline();
  };

  const _enableReorderable = () => {
    setReorderable(true);
  };

  const _enableEditTitles = () => {
    setEditableTitles(true);
  };

  const _resetTitles = () => {
    if (confirm(I18n.t('timeline.reset_titles_confirmation'))) {
      props.resetTitles();
      saveTimeline();
    }
  };

  const saveTimeline = () => {
    setReorderable(false);
    setEditableTitles(false);
    const toSave = { weeks: props.weeks };
    props.persistTimeline(toSave, props.course_id);
  };

  if (props.course.loading) {
    return <div />;
  }
  const weekMeetings = CourseDateUtils.weekMeetings(props.course, props.course.day_exceptions);
  const openWeeks = CourseDateUtils.openWeeks(weekMeetings);

  const courseProps = {
    key: 'wizard_handler',
    course: props.course,
    weeks: props.weeks,
    open_weeks: openWeeks
  };

  return (
    <div>
      <TransitionGroup
        classNames="wizard"
        component="div"
        timeout={500}
      >
        <Routes>
          <Route path="wizard" element={<Wizard {...courseProps} />} />
          <Route path="dates" element={<Meetings {...courseProps} />} />
        </Routes>
      </TransitionGroup>

      <Timeline
        loading={props.loading}
        course={props.course}
        weeks={props.weeks}
        allWeeks={props.allWeeks}
        allWeeksDates={props.allWeeksDates}
        week_meetings={weekMeetings}
        editableBlockIds={props.editableBlockIds}
        reorderable={reorderable}
        editableTitles={editableTitles}
        controls={props.controls}
        persistCourse={props.persistTimeline}
        saveGlobalChanges={saveTimeline}
        saveBlockChanges={saveTimeline}
        cancelBlockEditable={_cancelBlockEditable}
        cancelGlobalChanges={_cancelGlobalChanges}
        updateTitle={props.updateTitle}
        resetTitles={_resetTitles}
        updateBlock={props.updateBlock}
        enableReorderable={_enableReorderable}
        enableEditTitles={_enableEditTitles}
        all_training_modules={props.availableTrainingModules}
        addWeek={props.addWeek}
        addBlock={props.addBlock}
        deleteBlock={props.deleteBlock}
        insertBlock={props.insertBlock}
        deleteWeek={props.deleteWeek}
        deleteAllWeeks={props.deleteAllWeeks}
        setBlockEditable={props.setBlockEditable}
        nameHasChanged={() => false}
        edit_permissions={props.editPermissions}
        current_user={props.current_user}
      />
      {/* {grading} */}
    </div>
  );
};

TimelineHandler.propTypes = {
  course_id: PropTypes.string,
  course: PropTypes.object.isRequired,
  current_user: PropTypes.object,
  children: PropTypes.node,
  controls: PropTypes.func,
  weeks: PropTypes.array.isRequired,
  loading: PropTypes.bool,
  editableBlockIds: PropTypes.array,
  all_training_modules: PropTypes.array,
  fetchAllTrainingModules: PropTypes.func.isRequired,
  editPermissions: PropTypes.bool.isRequired
};

const mapStateToProps = state => ({
  weeks: getWeeksArray(state),
  allWeeks: getAllWeeksArray(state),
  allWeeksDates: getAllWeekDates(state),
  loading: state.timeline.loading || state.course.loading,
  editableBlockIds: state.timeline.editableBlockIds,
  availableTrainingModules: getAvailableTrainingModules(state),
  editPermissions: editPermissions(state)
});

const mapDispatchToProps = {
  addWeek,
  deleteWeek,
  addBlock,
  deleteBlock,
  persistTimeline,
  setBlockEditable,
  cancelBlockEditable,
  updateBlock,
  insertBlock,
  updateTitle,
  resetTitles,
  restoreTimeline,
  deleteAllWeeks,
  fetchAllTrainingModules
};

// Maintain Redux connection using connect higher-order component
export default connect(mapStateToProps, mapDispatchToProps)(TimelineHandler);
