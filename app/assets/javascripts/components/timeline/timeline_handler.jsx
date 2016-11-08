import React from 'react';
import TransitionGroup from 'react-addons-css-transition-group';

import Timeline from './timeline.cjsx';
import Grading from './grading.jsx';
import Editable from '../high_order/editable.jsx';

import CourseDateUtils from '../../utils/course_date_utils.coffee';

import ServerActions from '../../actions/server_actions.js';
import TimelineActions from '../../actions/timeline_actions.js';

import CourseStore from '../../stores/course_store.js';
import WeekStore from '../../stores/week_store.js';
import BlockStore from '../../stores/block_store.js';
import GradeableStore from '../../stores/gradeable_store.js';
import TrainingStore from '../../training/stores/training_store.coffee';

const getState = () =>
  ({
    loading: WeekStore.getLoadingStatus(),
    weeks: WeekStore.getWeeks(),
    blocks: BlockStore.getBlocks(),
    gradeables: GradeableStore.getGradeables(),
    all_training_modules: TrainingStore.getAllModules(),
    editable_block_ids: BlockStore.getEditableBlockIds(),
    editable_week_id: WeekStore.getEditableWeekId(),
    course: CourseStore.getCourse()
  })
;

const TimelineHandler = React.createClass({
  displayName: 'TimelineHandler',

  propTypes: {
    course_id: React.PropTypes.string,
    course: React.PropTypes.object,
    current_user: React.PropTypes.object,
    children: React.PropTypes.node,
    controls: React.PropTypes.func,
    weeks: React.PropTypes.array,
    gradeables: React.PropTypes.array,
    loading: React.PropTypes.bool,
    editable_block_ids: React.PropTypes.array,
    editable_week_id: React.PropTypes.number,
    all_training_modules: React.PropTypes.array
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
    const toSave = $.extend(true, {}, this.props);
    TimelineActions.persistTimeline(toSave, this.props.course_id);
    WeekStore.clearEditableWeekId();
    if (editableBlockId > 0) {
      return BlockStore.cancelBlockEditable(editableBlockId);
    }
    return BlockStore.clearEditableBlockIds();
  },

  render() {
    const meetings = CourseDateUtils.meetings(this.props.course);
    let weekMeetings = CourseDateUtils.weekMeetings(meetings, this.props.course, this.props.course.day_exceptions);
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
    } else if (this.props.current_user.admin || this.props.current_user.role > 0) {
      showGrading = true;
    } else if (this.props.gradeables.length === 0) {
      showGrading = false;
    } else {
      showGrading = true;
    }
    let grading = showGrading ? <Grading {...this.props} /> : null;

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
          week_meetings={weekMeetings}
          editable_block_ids={this.props.editable_block_ids}
          editable_week_id={this.props.editable_week_id}
          reorderable={this.state.reorderable}
          controls={this.props.controls}
          saveGlobalChanges={this.saveTimeline}
          saveBlockChanges={this.saveTimeline}
          cancelBlockEditable={this._cancelBlockEditable}
          cancelGlobalChanges={this._cancelGlobalChanges}
          enableReorderable={this._enableReorderable}
          all_training_modules={this.props.all_training_modules}
          edit_permissions={this.props.current_user.admin || this.props.current_user.role > 0}
        />
        {grading}
      </div>
    );
  }
});

export default Editable(TimelineHandler, [CourseStore, WeekStore, BlockStore, GradeableStore, TrainingStore], TimelineActions.persistTimeline, getState);
