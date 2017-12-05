import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { DragDropContext } from 'react-dnd';
import Touch from 'react-dnd-touch-backend';
import _ from 'lodash';

import Week from './week.jsx';
import EmptyWeek from './empty_week.jsx';
import Loading from '../common/loading.jsx';
import CourseLink from '../common/course_link.jsx';
import Affix from '../common/affix.jsx';

import WeekActions from '../../actions/week_actions.js';
import BlockActions from '../../actions/block_actions.js';
import CourseActions from '../../actions/course_actions.js';

import BlockStore from '../../stores/block_store.js';
import WeekStore from '../../stores/week_store.js';

import DateCalculator from '../../utils/date_calculator.js';
import CourseUtils from '../../utils/course_utils.js';
import CourseDateUtils from '../../utils/course_date_utils.js';

const Timeline = createReactClass({
  displayName: 'Timeline',

  propTypes: {
    loading: PropTypes.bool,
    course: PropTypes.object.isRequired,
    weeks: PropTypes.array,
    week_meetings: PropTypes.array,
    editable_block_ids: PropTypes.array,
    editable: PropTypes.bool,
    controls: PropTypes.func,
    saveGlobalChanges: PropTypes.func,
    cancelGlobalChanges: PropTypes.func,
    saveBlockChanges: PropTypes.func,
    cancelBlockEditable: PropTypes.func,
    all_training_modules: PropTypes.array,
    edit_permissions: PropTypes.bool,
    reorderable: PropTypes.bool,
    enableReorderable: PropTypes.func,
  },

  getInitialState() {
    return { unscrolled: true };
  },

  componentDidMount() {
    return window.addEventListener('scroll', this._handleScroll);
  },

  componentWillUnmount() {
    return window.removeEventListener('scroll', this._handleScroll);
  },

  hasTimeline() {
    return this.props.weeks && this.props.weeks.length;
  },

  addWeek() {
    return WeekActions.addWeek();
  },

  deleteWeek(weekId) {
    if (confirm(I18n.t('timeline.delete_week_confirmation'))) {
      return WeekActions.deleteWeek(weekId);
    }
  },

  deleteAllWeeks() {
    if (confirm(I18n.t('timeline.delete_weeks_confirmation'))) {
      return CourseActions.deleteAllWeeks(this.props.course.slug)
               .then(() => { return window.location.reload(); });
    }
  },

  _handleBlockDrag(targetIndex, block, target) {
    const originalIndexCheck = BlockStore.getBlocksInWeek(block.week_id).indexOf(block);
    if (originalIndexCheck !== targetIndex || block.week_id !== target.week_id) {
      const toWeek = WeekStore.getWeek(target.week_id);
      return this._moveBlock(block, toWeek, targetIndex);
    }
  },

  _moveBlock(block, toWeek, afterBlock) {
    return BlockActions.insertBlock(block, toWeek, afterBlock);
  },

  _handleMoveBlock(moveUp, blockId) {
    for (let i = 0; i < this.props.weeks.length; i++) {
      const week = this.props.weeks[i];
      const blocks = BlockStore.getBlocksInWeek(week.id);
      for (let j = 0; j < blocks.length; j++) {
        const block = blocks[j];
        if (blockId === block.id) {
          let atIndex;
          if ((moveUp && j === 0) || (!moveUp && j === blocks.length - 1)) {
            // Move to adjacent week
            const toWeek = this.props.weeks[moveUp ? i - 1 : i + 1];
            if (moveUp) {
              const toWeekBlocks = BlockStore.getBlocksInWeek(toWeek.id);
              atIndex = toWeekBlocks.length - 1;
            }
            this._moveBlock(block, toWeek, atIndex);
          } else {
            // Swap places with the adjacent block
            atIndex = moveUp ? j - 1 : j + 1;
            this._moveBlock(block, week, atIndex);
          }
          return;
        }
      }
    }
  },

  _canBlockMoveDown(week, weekIndexInTimeline, block, blockIndexInWeek) {
    if (weekIndexInTimeline === this.props.weeks.length - 1 && blockIndexInWeek === BlockStore.getBlocksInWeek(week.id).length - 1) { return false; }
    // TODO: return false if it's the last block in the last non-blackout week
    return true;
  },

  _canBlockMoveUp(week, weekIndexInTimeline, block, blockIndexInWeek) {
    if (weekIndexInTimeline === 0 && blockIndexInWeek === 0) { return false; }
    // TODO: return false if it's the first block in the first non-blackout week
    return true;
  },

  _scrolledToBottom() {
    const scrollTop = (document.documentElement && document.documentElement.scrollTop) || document.body.scrollTop;
    const scrollHeight = (document.documentElement && document.documentElement.scrollHeight) || document.body.scrollHeight;
    return (scrollTop + window.innerHeight) >= scrollHeight;
  },

  _handleScroll: _.throttle(function () {
    this.setState({ unscrolled: false });
    const scrollTop = window.scrollTop || document.body.scrollTop || window.pageYOffset;
    const bodyTop = document.body.getBoundingClientRect().top;
    const weekEls = document.getElementsByClassName('week');
    const navItems = document.getElementsByClassName('week-nav__item');
    return Array.prototype.forEach.call(weekEls, (el, i) => {
      const elTop = el.getBoundingClientRect().top - bodyTop;
      const topOffset = 90;
      if (scrollTop >= elTop - topOffset) {
        Array.prototype.forEach.call(navItems, item => {
          return item.classList.remove('is-current');
        }
        );
        if (!this._scrolledToBottom()) {
          return __guard__(navItems[i], x => x.classList.add('is-current'));
        }
        return __guard__(navItems[navItems.length - 1], x1 => x1.classList.add('is-current'));
      }
    }
    );
  }
  , 150),

  tooManyWeeks() {
    const nonEmptyWeeks = this.props.week_meetings.filter(week => week !== '()');
    return nonEmptyWeeks.length < this.props.weeks.length;
  },

  render() {
    if (this.props.loading) {
      return <Loading />;
    }

    const weekComponents = [];
    const weeksBeforeTimeline = CourseDateUtils.weeksBeforeTimeline(this.props.course);
    let i = 0;

    this.props.weeks.sort((a, b) => a.order - b.order);

    this.props.weeks.forEach(w =>
      w.blocks.sort((a, b) => a.order - b.order)
    );

    let tooManyWeeksWarning;
    if (this.tooManyWeeks()) {
      tooManyWeeksWarning = (
        <li className="timeline-warning">
          WARNING! There are not enough non-holiday weeks before the assignment end date! You can click &apos;Edit Course Dates&apos; to set the meeting dates and holiday dates.
        </li>
      );
    }
    // For each week, first insert an extra empty week for each week with empty
    // week meetings, which indicates a blackout week. Then insert the week itself.
    // The index 'i' represents the zero-index week number; both empty and non-empty
    // weeks are included in this numbering scheme.
    this.props.weeks.forEach((week, weekIndex) => {
      while (this.props.week_meetings[i] === '()') {
        const emptyWeekKey = `empty-week-${i}`;
        const weekAnchorName = `week-${i + 1 + weeksBeforeTimeline}`;
        weekComponents.push((
          <div key={emptyWeekKey}>
            <a className="timeline__anchor" name={weekAnchorName} />
            <EmptyWeek
              course={this.props.course}
              edit_permissions={this.props.edit_permissions}
              index={i + 1}
              timeline_start={this.props.course.timeline_start}
              timeline_end={this.props.course.timeline_end}
              weeksBeforeTimeline={weeksBeforeTimeline}
            />
          </div>
        )
        );
        i++;
      }

      const weekAnchorName = `week-${i + 1 + weeksBeforeTimeline}`;
      weekComponents.push((
        <div key={week.id}>
          <a className="timeline__anchor" name={weekAnchorName} />
          <Week
            week={week}
            index={i + 1}
            reorderable={this.props.reorderable}
            blocks={BlockStore.getBlocksInWeek(week.id)}
            deleteWeek={this.deleteWeek.bind(this, week.id)}
            meetings={this.props.week_meetings[i]}
            timeline_start={this.props.course.timeline_start}
            timeline_end={this.props.course.timeline_end}
            all_training_modules={this.props.all_training_modules}
            editable_block_ids={this.props.editable_block_ids}
            edit_permissions={this.props.edit_permissions}
            saveBlockChanges={this.props.saveBlockChanges}
            cancelBlockEditable={this.props.cancelBlockEditable}
            saveGlobalChanges={this.props.saveGlobalChanges}
            canBlockMoveUp={this._canBlockMoveUp.bind(this, week, weekIndex)}
            canBlockMoveDown={this._canBlockMoveDown.bind(this, week, weekIndex)}
            onMoveBlockUp={this._handleMoveBlock.bind(this, true)}
            onMoveBlockDown={this._handleMoveBlock.bind(this, false)}
            onBlockDrag={this._handleBlockDrag}
            weeksBeforeTimeline={weeksBeforeTimeline}
          />
        </div>
      )
      );
      return i++;
    }
    );

    // If there are no weeks at all, put in a special placeholder week with the
    // emptyTimeline parameter
    let noWeeks;
    if (!this.props.loading && this.props.weeks.length === 0) {
      noWeeks = (
        <EmptyWeek
          course={this.props.course}
          index={1}
          emptyTimeline
          timeline_start={this.props.course.timeline_start}
          timeline_end={this.props.course.timeline_end}
          edit_permissions={this.props.edit_permissions}
        />
      );
    }

    let wizardLink;
    if (weekComponents.length <= 0 && this.props.edit_permissions && this.props.course.type === 'ClassroomProgramCourse') {
      const wizardUrl = `/courses/${this.props.course.slug}/timeline/wizard`;
      wizardLink = <CourseLink to={wizardUrl} className="button dark button--block timeline__add-assignment">Add Assignment</CourseLink>;
    }

    const controls = this.props.reorderable || __guard__(this.props, x => x.editable_block_ids.length) > 1 ? (
      <div>
        <button className="button dark button--block" onClick={this.props.saveGlobalChanges}>
          {I18n.t('timeline.save_all_changes')}
        </button>
        <button className="button button--clear button--block" onClick={this.props.cancelGlobalChanges}>
          {I18n.t('timeline.discard_all_changes')}
        </button>
      </div>
    ) : undefined;

    let reorderableControls;
    let editCourseDates;
    let addWeekLink;
    if (this.props.edit_permissions) {
      if (this.props.reorderable) {
        reorderableControls = (
          <div className="reorderable-controls">
            <h5>{I18n.t('timeline.arrange_timeline')}</h5>
            <p className="muted">{I18n.t('timeline.arrange_timeline_instructions')}</p>
          </div>
        );
      } else if (this.props.editable_block_ids.length === 0) {
        reorderableControls = (
          <div className="reorderable-controls">
            <button className="button border button--block" onClick={this.props.enableReorderable}>Arrange Timeline</button>
          </div>
        );
      }

      const courseLink = `/courses/${this.props.course.slug}/timeline/dates`;
      editCourseDates = (
        <CourseLink className="week-nav__action week-nav__link" to={courseLink}>{CourseUtils.i18n('edit_course_dates', this.props.course.string_prefix)}</CourseLink>
      );

      const start = moment(this.props.course.timeline_start);
      const end = moment(this.props.course.timeline_end);
      const timelineFull = (moment(end - start).weeks()) - weekComponents.length <= 0;
      addWeekLink = timelineFull ? (
        <li>
          <label className="week-nav__action week-nav__link disabled tooltip-trigger">
            {I18n.t('timeline.add_week')}
            <div className="tooltip dark">
              <p>{I18n.t('timeline.unable_to_add_week')}</p>
            </div>
          </label>
        </li>
      ) : (
        <li>
          <button className="week-nav__add-week" onClick={this.addWeek}>Add Week</button>
        </li>
      );
    }

    const weekNav = weekComponents.map((week, navIndex) => {
      let navClassName = 'week-nav__item';
      if (navIndex === 0) {
        navClassName += ' is-current';
      }

      const dateCalc = new DateCalculator(this.props.course.timeline_start, this.props.course.timeline_end, navIndex, { zeroIndexed: true });
      const navWeekKey = `week-${navIndex}`;
      const navWeekLink = `#week-${navIndex + 1 + weeksBeforeTimeline}`;
      return (
        <li className={navClassName} key={navWeekKey}>
          <a href={navWeekLink}>{week.title || I18n.t('timeline.week_number', { number: navIndex + 1 + weeksBeforeTimeline })}</a>
          <span className="pull-right">{dateCalc.start()} - {dateCalc.end()}</span>
        </li>
      );
    });

    let restartTimeline;
    // Only show the 'Delete Timeline' button if user can edit, course is unsubmitted,
    // and the timeline is not already empty.
    if (this.props.edit_permissions && !this.props.course.submitted && this.hasTimeline()) {
      restartTimeline = (
        <button className="button border danger button--block" onClick={this.deleteAllWeeks}>
          {I18n.t('timeline.delete_timeline_and_start_over')}
        </button>
      );
    }

    const sidebar = this.props.course.id ? (
      <div className="timeline__week-nav">
        <Affix offset={100}>
          <section className="timeline-ctas float-container">
            <span>{wizardLink}</span>
            {reorderableControls}
            {controls}
          </section>
          <section className="timeline-ctas float-container">
            {restartTimeline}
          </section>
          <div className="panel">
            <ol>
              {weekNav}
              {addWeekLink}
            </ol>
            {editCourseDates}
            <a className="week-nav__action week-nav__link" href="#grading">Grading</a>
          </div>
        </Affix>
      </div>
    ) : (
      <div className="timeline__week-nav" />
    );

    return (
      <div>
        <div className="timeline__content">
          <ul className="list-unstyled timeline__weeks">
            {tooManyWeeksWarning}
            {weekComponents}
            {noWeeks}
          </ul>
          {sidebar}
        </div>
      </div>
    );
  }
});

export default DragDropContext(Touch({ enableMouseEvents: true }))(Timeline);

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}
