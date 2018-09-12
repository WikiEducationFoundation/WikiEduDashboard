import React from 'react';
import { connect } from 'react-redux';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import TransitionGroup from 'react-transition-group/CSSTransitionGroup';

import Timeline from './timeline.jsx';
import Grading from './grading.jsx';
import CourseDateUtils from '../../utils/course_date_utils.js';

import ServerActions from '../../actions/server_actions.js';

import BlockStore from '../../stores/block_store.js';
import TrainingStore from '../../training/stores/training_store.js';
import { addWeek, deleteWeek, persistTimeline } from '../../actions/timeline_actions';
import { getWeeksArray, getBlocksArray } from '../../selectors';


const TimelineHandler = createReactClass({
  displayName: 'TimelineHandler',

  propTypes: {
    course_id: PropTypes.string,
    course: PropTypes.object.isRequired,
    current_user: PropTypes.object,
    children: PropTypes.node,
    controls: PropTypes.func,
    weeks: PropTypes.array.isRequired,
    weeksObject: PropTypes.object.isRequired,
    blocks: PropTypes.array,
    loading: PropTypes.bool,
    editable_block_ids: PropTypes.array,
    all_training_modules: PropTypes.array
  },

  getInitialState() {
    return { reorderable: false };
  },

  componentWillMount() {
    ServerActions.fetch('timeline', this.props.course_id);
    return ServerActions.fetchAllTrainingModules();
  },

  _cancelBlockEditable(blockId) {
    BlockStore.restore();
    return BlockStore.cancelBlockEditable(blockId);
  },

  _cancelGlobalChanges() {
    this.setState({ reorderable: false });
    BlockStore.restore();
    return BlockStore.clearEditableBlockIds();
  },

  _enableReorderable() {
    return this.setState({ reorderable: true });
  },

  saveTimeline(editableBlockId = 0) {
    this.setState({ reorderable: false });
    const toSave = { ...this.props };
    this.props.persistTimeline(toSave, this.props.course_id);
    if (editableBlockId > 0) {
      return BlockStore.cancelBlockEditable(editableBlockId);
    }
    return BlockStore.clearEditableBlockIds();
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
    let showGrading;
    if (this.state.reorderable) {
      showGrading = false;
    } else {
      showGrading = true;
    }
    const grading = showGrading ? <Grading
      weeks={this.props.weeks}
      blocks={this.props.blocks}
      editable={this.props.editable}
      current_user={this.props.current_user}
      persistCourse={this.saveTimeline}
      resetState={() => {}}
      nameHasChanged={() => false}
    /> : null;

    return (
      <div>
        <TransitionGroup
          transitionName="wizard"
          component="div"
          transitionEnterTimeout={500}
          transitionLeaveTimeout={500}
        >
          {outlet}
        </TransitionGroup>
        <Timeline
          loading={this.props.loading}
          course={this.props.course}
          weeks={this.props.weeks}
          weeksObject={this.props.weeksObject}
          week_meetings={weekMeetings}
          editable_block_ids={BlockStore.getEditableBlockIds()}
          reorderable={this.state.reorderable}
          controls={this.props.controls}
          persistCourse={this.props.persistTimeline}
          saveGlobalChanges={this.saveTimeline}
          saveBlockChanges={this.saveTimeline}
          cancelBlockEditable={this._cancelBlockEditable}
          cancelGlobalChanges={this._cancelGlobalChanges}
          enableReorderable={this._enableReorderable}
          all_training_modules={TrainingStore.getAllModules()}
          addWeek={this.props.addWeek}
          deleteWeek={this.props.deleteWeek}
          resetState={() => {}}
          nameHasChanged={() => false}
          edit_permissions={this.props.current_user.admin || this.props.current_user.role > 0}
        />
        {grading}
      </div>
    );
  }
});

const mapStateToProps = state => ({
  weeks: getWeeksArray(state),
  weeksObject: state.timeline.weeks,
  loading: state.timeline.loading,
  blocks: getBlocksArray(state)
});

const mapDispatchToProps = {
  addWeek,
  deleteWeek,
  persistTimeline
};

export default connect(mapStateToProps, mapDispatchToProps)(TimelineHandler);
