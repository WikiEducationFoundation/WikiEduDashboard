import React from 'react';
import { connect } from 'react-redux';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import TransitionGroup from '../common/css_transition_group';

import Timeline from './timeline.jsx';
// import Grading from './grading.jsx';
import CourseDateUtils from '../../utils/course_date_utils.js';

import { fetchAllTrainingModules } from '../../actions/training_actions';

import { addWeek, deleteWeek, persistTimeline, setBlockEditable, cancelBlockEditable,
  updateBlock, addBlock, deleteBlock, insertBlock, restoreTimeline, deleteAllWeeks } from '../../actions/timeline_actions';
import { getWeeksArray, getAvailableTrainingModules, editPermissions } from '../../selectors';

const TimelineHandler = createReactClass({
  displayName: 'TimelineHandler',

  propTypes: {
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
  },

  getInitialState() {
    return { reorderable: false };
  },

  componentDidMount() {
    return this.props.fetchAllTrainingModules();
  },

  _cancelBlockEditable(blockId) {
    // TODO: Restore to persisted state for this block only
    return this.props.cancelBlockEditable(blockId);
  },

  _cancelGlobalChanges() {
    this.setState({ reorderable: false });
    this.props.restoreTimeline();
  },

  _enableReorderable() {
    return this.setState({ reorderable: true });
  },

  saveTimeline() {
    this.setState({ reorderable: false });
    const toSave = { weeks: this.props.weeks };
    this.props.persistTimeline(toSave, this.props.course_id);
  },

  render() {
    const meetings = CourseDateUtils.meetings(this.props.course);
    const weekMeetings = CourseDateUtils.weekMeetings(meetings, this.props.course, this.props.course.day_exceptions);
    const openWeeks = CourseDateUtils.openWeeks(weekMeetings);

    let outlet;
    // This passes props to Meetings and Wizard, which are children specified in
    // router.jsx.
    if (this.props.children) {
      outlet = React.cloneElement(this.props.children, {
        key: 'wizard_handler',
        course: this.props.course,
        weeks: this.props.weeks,
        week_meetings: weekMeetings,
        meetings,
        open_weeks: openWeeks
      });
    }

    // Grading
    // let showGrading;
    // if (this.state.reorderable) {
    //   showGrading = false;
    // } else {
    //   showGrading = true;
    // }
    // const grading = showGrading ? (<Grading
    //   weeks={this.props.weeks}
    //   editable={this.props.editable}
    //   current_user={this.props.current_user}
    //   persistCourse={this.saveTimeline}
    //   updateBlock={this.props.updateBlock}
    //   resetState={() => {}}
    //   nameHasChanged={() => false}
    // />) : null;

    return (
      <div>
        <TransitionGroup
          classNames="wizard"
          component="div"
          timeout={500}
        >
          {outlet}
        </TransitionGroup>
        <Timeline
          loading={this.props.loading}
          course={this.props.course}
          weeks={this.props.weeks}
          week_meetings={weekMeetings}
          editableBlockIds={this.props.editableBlockIds}
          reorderable={this.state.reorderable}
          controls={this.props.controls}
          persistCourse={this.props.persistTimeline}
          saveGlobalChanges={this.saveTimeline}
          saveBlockChanges={this.saveTimeline}
          cancelBlockEditable={this._cancelBlockEditable}
          cancelGlobalChanges={this._cancelGlobalChanges}
          updateBlock={this.props.updateBlock}
          enableReorderable={this._enableReorderable}
          all_training_modules={this.props.availableTrainingModules}
          addWeek={this.props.addWeek}
          addBlock={this.props.addBlock}
          deleteBlock={this.props.deleteBlock}
          insertBlock={this.props.insertBlock}
          deleteWeek={this.props.deleteWeek}
          deleteAllWeeks={this.props.deleteAllWeeks}
          setBlockEditable={this.props.setBlockEditable}
          resetState={() => {}}
          nameHasChanged={() => false}
          edit_permissions={this.props.editPermissions}
        />
        {/* {grading} */}
      </div>
    );
  }
});

const mapStateToProps = state => ({
  weeks: getWeeksArray(state),
  loading: state.timeline.loading,
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
  restoreTimeline,
  deleteAllWeeks,
  fetchAllTrainingModules
};

export default connect(mapStateToProps, mapDispatchToProps)(TimelineHandler);
