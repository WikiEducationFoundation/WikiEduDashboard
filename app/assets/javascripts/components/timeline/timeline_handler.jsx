import React from 'react';
import { connect } from 'react-redux';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import TransitionGroup from '../common/css_transition_group';
import withRouter from '../util/withRouter';
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
import { getWeeksArray, getAllWeeksArray, getAvailableTrainingModules, editPermissions } from '../../selectors';

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
    return {
      reorderable: false,
      editableTitles: false
    };
  },

  componentDidMount() {
    document.title = `${this.props.course.title} - ${I18n.t('courses.timeline_link')}`;
    return this.props.fetchAllTrainingModules();
  },

  _cancelBlockEditable(blockId) {
    // TODO: Restore to persisted state for this block only
    return this.props.cancelBlockEditable(blockId);
  },

  _cancelGlobalChanges() {
    this.setState({ reorderable: false });
    this.setState({ editableTitles: false });
    this.props.restoreTimeline();
  },

  _enableReorderable() {
    return this.setState({ reorderable: true });
  },

  _enableEditTitles() {
    return this.setState({ editableTitles: true });
  },

  _resetTitles() {
    if (confirm(I18n.t('timeline.reset_titles_confirmation'))) {
      this.props.resetTitles();
      this.saveTimeline();
    }
  },

  saveTimeline() {
    this.setState({ reorderable: false });
    this.setState({ editableTitles: false });
    const toSave = { weeks: this.props.weeks };
    this.props.persistTimeline(toSave, this.props.course_id);
  },

  render() {
    if (this.props.course.loading) {
      return <div />;
    }
    const weekMeetings = CourseDateUtils.weekMeetings(this.props.course, this.props.course.day_exceptions);
    const openWeeks = CourseDateUtils.openWeeks(weekMeetings);

    const courseProps = {
      key: 'wizard_handler',
      course: this.props.course,
      weeks: this.props.weeks,
      open_weeks: openWeeks
    };

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
          <Routes>
            <Route path="wizard" element={<Wizard {...courseProps} />} />
            <Route path="dates" element={<Meetings {...courseProps} />} />
          </Routes>
        </TransitionGroup>

        <Timeline
          loading={this.props.loading}
          course={this.props.course}
          weeks={this.props.weeks}
          allWeeks={this.props.allWeeks}
          week_meetings={weekMeetings}
          editableBlockIds={this.props.editableBlockIds}
          reorderable={this.state.reorderable}
          editableTitles={this.state.editableTitles}
          controls={this.props.controls}
          persistCourse={this.props.persistTimeline}
          saveGlobalChanges={this.saveTimeline}
          saveBlockChanges={this.saveTimeline}
          cancelBlockEditable={this._cancelBlockEditable}
          cancelGlobalChanges={this._cancelGlobalChanges}
          updateTitle={this.props.updateTitle}
          resetTitles={this._resetTitles}
          updateBlock={this.props.updateBlock}
          enableReorderable={this._enableReorderable}
          enableEditTitles={this._enableEditTitles}
          all_training_modules={this.props.availableTrainingModules}
          addWeek={this.props.addWeek}
          addBlock={this.props.addBlock}
          deleteBlock={this.props.deleteBlock}
          insertBlock={this.props.insertBlock}
          deleteWeek={this.props.deleteWeek}
          deleteAllWeeks={this.props.deleteAllWeeks}
          setBlockEditable={this.props.setBlockEditable}
          nameHasChanged={() => false}
          edit_permissions={this.props.editPermissions}
          current_user={this.props.current_user}
        />
        {/* {grading} */}
      </div>
    );
  }
});

const mapStateToProps = state => ({
  weeks: getWeeksArray(state),
  allWeeks: getAllWeeksArray(state),
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

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(TimelineHandler));
