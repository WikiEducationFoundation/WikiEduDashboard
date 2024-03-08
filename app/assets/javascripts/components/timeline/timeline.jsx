import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { HTML5Backend } from 'react-dnd-html5-backend';
import { DndProvider } from 'react-dnd';
import { throttle } from 'lodash-es';

import Week from './week.jsx';
import EmptyWeek from './empty_week.jsx';
import Loading from '../common/loading.jsx';
import CourseLink from '../common/course_link.jsx';
import Affix from '../common/affix.jsx';
import EditableRedux from '../high_order/editable_redux';

import DateCalculator from '../../utils/date_calculator.js';
import CourseUtils from '../../utils/course_utils.js';
import CourseDateUtils from '../../utils/course_date_utils.js';
import { toDate } from '../../utils/date_utils.js';
import { differenceInWeeks } from 'date-fns';

const Timeline = createReactClass({
  displayName: 'Timeline',

  propTypes: {
    loading: PropTypes.bool,
    course: PropTypes.object.isRequired,
    weeks: PropTypes.array,
    allWeeks: PropTypes.array,
    week_meetings: PropTypes.array,
    editableBlockIds: PropTypes.array,
    editable: PropTypes.bool,
    controls: PropTypes.func,
    addWeek: PropTypes.func.isRequired,
    addBlock: PropTypes.func.isRequired,
    insertBlock: PropTypes.func.isRequired,
    deleteWeek: PropTypes.func.isRequired,
    deleteAllWeeks: PropTypes.func.isRequired,
    saveGlobalChanges: PropTypes.func,
    cancelGlobalChanges: PropTypes.func,
    updateTitle: PropTypes.func,
    resetTitles: PropTypes.func,
    saveBlockChanges: PropTypes.func,
    cancelBlockEditable: PropTypes.func,
    all_training_modules: PropTypes.array,
    edit_permissions: PropTypes.bool,
    reorderable: PropTypes.bool,
    editableTitles: PropTypes.bool,
    enableReorderable: PropTypes.func,
    enableEditTitles: PropTypes.func,
    current_user: PropTypes.object
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

  getBlocksInWeek(weekId) {
    const week = this.props.weeks.find(thisWeek => thisWeek.id === weekId);
    return week.blocks;
  },

  usingCustomTitles() {
    return this.props.weeks.some(week => week.title);
  },

  hasTimeline() {
    return this.props.weeks && this.props.weeks.length;
  },

  addWeek() {
    const lastWeek = document.getElementsByClassName(`week-${this.props.weeks.length}`)[0];
    const scrollTop = window.scrollY || document.body.scrollTop;
    const bottom = Math.abs(__guard__(lastWeek, x => x.getBoundingClientRect().bottom));
    const elBottom = (bottom + scrollTop) - 50;
    window.scrollTo({ top: elBottom, behavior: 'smooth' });
    return this.props.addWeek();
  },

  deleteWeek(weekId) {
    if (confirm(I18n.t('timeline.delete_week_confirmation'))) {
      return this.props.deleteWeek(weekId);
    }
  },

  deleteAllWeeks() {
    if (confirm(I18n.t('timeline.delete_weeks_confirmation'))) {
      return this.props.deleteAllWeeks(this.props.course.slug)
               .then(() => { return window.location.reload(); });
    }
  },

  _handleBlockDrag(targetIndex, block, target) {
    const originalIndexCheck = this.getBlocksInWeek(block.week_id).indexOf(block);
    if (originalIndexCheck !== targetIndex || block.week_id !== target.week_id) {
      return this._moveBlock(block, target.week_id, targetIndex);
    }
  },

  _moveBlock(block, newWeekId, targetIndex) {
    return this.props.insertBlock(block, newWeekId, targetIndex);
  },

  _handleMoveBlock(moveUp, blockId) {
    for (let i = 0; i < this.props.weeks.length; i += 1) {
      const week = this.props.weeks[i];
      const blocks = this.getBlocksInWeek(week.id);
      for (let j = 0; j < blocks.length; j += 1) {
        const block = blocks[j];
        if (blockId === block.id) {
          let atIndex;
          if ((moveUp && j === 0) || (!moveUp && j === blocks.length - 1)) {
            // Move to adjacent week
            const toWeek = this.props.weeks[moveUp ? i - 1 : i + 1];
            if (moveUp) {
              const toWeekBlocks = this.getBlocksInWeek(toWeek.id);
              atIndex = toWeekBlocks.length;
            }
            this._moveBlock(block, toWeek.id, atIndex);
          } else {
            // Swap places with the adjacent block
            atIndex = moveUp ? j - 1 : j + 1;
            this._moveBlock(block, week.id, atIndex);
          }
          return;
        }
      }
    }
  },
  _canBlockMoveDown(week, weekIndexInTimeline, block, blockIndexInWeek) {
    if (weekIndexInTimeline === this.props.weeks.length - 1 && blockIndexInWeek === this.getBlocksInWeek(week.id).length - 1) { return false; }
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

  _handleScroll: throttle(function () {
    this.setState({ unscrolled: false });
    const scrollTop = window.scrollTop || document.body.scrollTop || window.pageYOffset;
    const bodyTop = document.body.getBoundingClientRect().top;
    const weekEls = document.getElementsByClassName('week');
    const navItems = document.getElementsByClassName('week-nav__item');
    return Array.prototype.forEach.call(weekEls, (el, i) => {
      const elTop = el.getBoundingClientRect().top - bodyTop;
      const topOffset = 90;
      if (scrollTop >= elTop - topOffset) {
        Array.prototype.forEach.call(navItems, (item) => {
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
  }, 150),

  tooManyWeeks() {
    const nonEmptyWeeks = this.props.week_meetings.filter(week => week.length > 0);
    return nonEmptyWeeks.length < this.props.weeks.length;
  },

  render() {
    if (this.props.loading) {
      return <Loading />;
    }

    const weekComponents = [];
    const weeksBeforeTimeline = CourseDateUtils.weeksBeforeTimeline(this.props.course);
    const usingCustomTitles = this.usingCustomTitles();
    const weekNavInfo = [];

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
    // Using allWeeks prop to render all the weeks
    this.props.allWeeks.forEach((week, index) => {
      const weekAnchorName = `week-${index + 1 + weeksBeforeTimeline}`;
      // if week is empty
      if (week.empty) {
        const emptyWeekKey = `empty-week-${index}`;
        weekNavInfo.push({ emptyWeek: true, title: undefined });
        weekComponents.push((
          <div key={emptyWeekKey}>
            <a className="timeline__anchor" name={weekAnchorName} />
            <EmptyWeek
              course={this.props.course}
              edit_permissions={this.props.edit_permissions}
              index={index + 1}
              usingCustomTitles={usingCustomTitles}
              timeline_start={this.props.course.timeline_start}
              timeline_end={this.props.course.timeline_end}
              weeksBeforeTimeline={weeksBeforeTimeline}
              addWeek={this.props.addWeek}
            />
          </div>
        ));
      } else {
        weekNavInfo.push({ emptyWeek: false, title: week.title });
        weekComponents.push((
          <div key={week.id}>
            <a className="timeline__anchor" name={weekAnchorName} />
            <Week
              week={week}
              index={index + 1}
              reorderable={this.props.reorderable}
              editableTitles={this.props.editableTitles}
              usingCustomTitles={usingCustomTitles}
              updateTitle={this.props.updateTitle}
              blocks={week.blocks}
              deleteWeek={this.deleteWeek.bind(this, week.id)}
              meetings={week.meetings}
              timeline_start={this.props.course.timeline_start}
              timeline_end={this.props.course.timeline_end}
              all_training_modules={this.props.all_training_modules}
              editableBlockIds={this.props.editableBlockIds}
              edit_permissions={this.props.edit_permissions}
              saveBlockChanges={this.props.saveBlockChanges}
              setBlockEditable={this.props.setBlockEditable}
              cancelBlockEditable={this.props.cancelBlockEditable}
              updateBlock={this.props.updateBlock}
              addBlock={this.props.addBlock}
              deleteBlock={this.props.deleteBlock}
              saveGlobalChanges={this.props.saveGlobalChanges}
              canBlockMoveUp={this._canBlockMoveUp.bind(this, week, (week.order - 1))}
              canBlockMoveDown={this._canBlockMoveDown.bind(this, week, (week.order - 1))}
              onMoveBlockUp={this._handleMoveBlock.bind(this, true)}
              onMoveBlockDown={this._handleMoveBlock.bind(this, false)}
              onBlockDrag={this._handleBlockDrag}
              weeksBeforeTimeline={weeksBeforeTimeline}
              trainingLibrarySlug={this.props.course.training_library_slug}
              current_user={this.props.current_user}
              moveBlock={this._moveBlock}
            />
          </div>
        )
        );
      }
    });

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
          addWeek={this.props.addWeek}
        />
      );
    }

    let wizardLink;
    if (weekComponents.length <= 0 && this.props.edit_permissions && this.props.course.type === 'ClassroomProgramCourse') {
      const wizardUrl = `/courses/${this.props.course.slug}/timeline/wizard`;
      wizardLink = <CourseLink to={wizardUrl} className="button dark button--block timeline__add-assignment">Add Assignment</CourseLink>;
    }

    const saveChangesButton = (
      <button className="button dark button--block" onClick={this.props.saveGlobalChanges}>
        {I18n.t('timeline.save_all_changes')}
      </button>
    );
    const cancelChangesButton = (
      <button className="button button--clear button--block" onClick={this.props.cancelGlobalChanges}>
        {I18n.t('timeline.discard_all_changes')}
      </button>
    );
    const resetTitlesButton = (
      <button className="button button--clear button--block" onClick={this.props.resetTitles}>
        {I18n.t('timeline.reset_titles')}
      </button>
    );
    const reorderActionButtons = this.props.reorderable || __guard__(this.props, x => x.editableBlockIds.length) > 1 ? (
      <div>
        {saveChangesButton}
        {cancelChangesButton}
      </div>
    ) : null;
    const titlesActionButtons = this.props.editableTitles ? (
      <div>
        {saveChangesButton}
        {cancelChangesButton}
        {resetTitlesButton}
      </div>
    ) : null;

    let reorderableControls;
    let editWeekTitles;
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
      } else if (this.props.editableBlockIds.length === 0) {
        reorderableControls = (
          <div className="reorderable-controls">
            <button className="button border button--block" onClick={this.props.enableReorderable}>{I18n.t('timeline.arrange_timeline')}</button>
          </div>
        );
      }

      // if currently editing titles show info, otherwise show button
      if (this.props.editableTitles) {
        editWeekTitles = (
          <div className="edit-week-titles">
            <h5>{I18n.t('timeline.edit_titles')}</h5>
            <p className="muted">{I18n.t('timeline.edit_titles_info')}</p>
          </div>
        );
      } else {
        editWeekTitles = (
          <div className="edit-week-titles">
            <button className="button border button--block" onClick={this.props.enableEditTitles}>{I18n.t('timeline.edit_titles')}</button>
          </div>
        );
      }

      const courseLink = `/courses/${this.props.course.slug}/timeline/dates`;
      editCourseDates = (
        <CourseLink className="week-nav__action week-nav__link" to={courseLink}>{CourseUtils.i18n('edit_course_dates', this.props.course.string_prefix)}</CourseLink>
      );

      const start = toDate(this.props.course.timeline_start);
      const end = toDate(this.props.course.timeline_end);
      const weeksDiff = differenceInWeeks(end, start, { roundingMethod: 'ceil' });
      const timelineFull = weeksDiff - weekComponents.length <= 0;
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

    const weekNav = weekNavInfo.map((weekInfo, navIndex) => {
      let navClassName = 'week-nav__item';
      if (navIndex === 0) {
        navClassName += ' is-current';
      }

      const datesStr = DateCalculator.calculateDates(
        this.props.course.timeline_start, 
        this.props.course.timeline_end, 
        navIndex, 
        { zeroIndexed: true }
      );
      
      const [startDate, endDate] = datesStr.split(' - ');
      
      const navWeekKey = `week-${navIndex}`;
      const navWeekLink = `#week-${navIndex + 1 + weeksBeforeTimeline}`;
      
      // if using custom titles, show only titles, otherwise, show default titles and dates
      let navItem;
      if (usingCustomTitles) {
        let navTitle = '';
        if (weekInfo.emptyWeek) {
          navTitle = I18n.t('timeline.week_number', { number: datesStr });
        } else {
          navTitle = weekInfo.title ? weekInfo.title : I18n.t('timeline.week_number', { number: navIndex + 1 + weeksBeforeTimeline });
        }
        navItem = (
          <li className={navClassName} key={navWeekKey}>
            <a className="no-nav-dates" href={navWeekLink}>{navTitle}</a>
          </li>
        );
      } else {
        navItem = (
          <li className={navClassName} key={navWeekKey}>
            <a href={navWeekLink}>{I18n.t('timeline.week_number', { number: navIndex + 1 + weeksBeforeTimeline })}</a>
            <span className="pull-right">{startDate} - {endDate}</span>
          </li>
        );
      }

      return navItem;
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
            {reorderActionButtons}
          </section>
          <section className="timeline-ctas float-container">
            {editWeekTitles}
            {titlesActionButtons}
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
            {/* <a className="week-nav__action week-nav__link" href="#grading">Grading</a> */}
          </div>
        </Affix>
      </div>
    ) : (
      <div className="timeline__week-nav" />
    );

    return (
      <DndProvider backend={HTML5Backend}>
        <div className="timeline__content">
          <ul className="list-unstyled timeline__weeks">
            {tooManyWeeksWarning}
            {weekComponents}
            {noWeeks}
          </ul>
          {sidebar}
        </div>
      </DndProvider>
    );
  }
});

export default EditableRedux(Timeline);

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}
