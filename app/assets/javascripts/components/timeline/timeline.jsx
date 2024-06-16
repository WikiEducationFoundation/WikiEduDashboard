import React, { useState, useEffect, useCallback } from 'react';
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

const Timeline = (props) => {
  const [unscrolled, setUnscrolled] = useState(true);

  const getBlocksInWeek = (weekId) => {
    const week = props.weeks.find(thisWeek => thisWeek.id === weekId);
    return week.blocks;
  };

  const usingCustomTitles = () => {
    return props.weeks.some(week => week.title);
  };

  const hasTimeline = () => {
    return props.weeks && props.weeks.length;
  };

  const addWeek = () => {
    const lastWeek = document.getElementsByClassName(`week-${props.weeks.length}`)[0];
    const scrollTop = window.scrollY || document.body.scrollTop;
    const bottom = Math.abs(__guard__(lastWeek, x => x.getBoundingClientRect().bottom));
    const elBottom = (bottom + scrollTop) - 50;
    window.scrollTo({ top: elBottom, behavior: 'smooth' });
    return props.addWeek();
  };

  const deleteWeek = (weekId) => {
    if (confirm(I18n.t('timeline.delete_week_confirmation'))) {
      return props.deleteWeek(weekId);
    }
  };

  const deleteAllWeeks = () => {
    if (confirm(I18n.t('timeline.delete_weeks_confirmation'))) {
      return props.deleteAllWeeks(props.course.slug)
        .then(() => window.location.reload());
    }
  };

  const moveBlock = (block, newWeekId, targetIndex) => {
    return props.insertBlock(block, newWeekId, targetIndex);
  };

  const handleMoveBlock = (moveUp, blockId) => {
    for (let i = 0; i < props.weeks.length; i += 1) {
      const week = props.weeks[i];
      const blocks = getBlocksInWeek(week.id);
      for (let j = 0; j < blocks.length; j += 1) {
        const block = blocks[j];
        if (blockId === block.id) {
          let atIndex;
          if ((moveUp && j === 0) || (!moveUp && j === blocks.length - 1)) {
            const toWeek = props.weeks[moveUp ? i - 1 : i + 1];
            if (moveUp) {
              const toWeekBlocks = getBlocksInWeek(toWeek.id);
              atIndex = toWeekBlocks.length;
            }
            moveBlock(block, toWeek.id, atIndex);
          } else {
            atIndex = moveUp ? j - 1 : j + 1;
            moveBlock(block, week.id, atIndex);
          }
          return;
        }
      }
    }
  };

  const canBlockMoveDown = (week, weekIndexInTimeline, block, blockIndexInWeek) => {
    if (weekIndexInTimeline === props.weeks.length - 1 && blockIndexInWeek === getBlocksInWeek(week.id).length - 1) {
      return false;
    }
    return true;
  };

  const canBlockMoveUp = (week, weekIndexInTimeline, block, blockIndexInWeek) => {
    if (weekIndexInTimeline === 0 && blockIndexInWeek === 0) {
      return false;
    }
    return true;
  };

  const scrolledToBottom = () => {
    const scrollTop = (document.documentElement && document.documentElement.scrollTop) || document.body.scrollTop;
    const scrollHeight = (document.documentElement && document.documentElement.scrollHeight) || document.body.scrollHeight;
    return (scrollTop + window.innerHeight) >= scrollHeight;
  };

  const handleScroll = useCallback(throttle(() => {
    setUnscrolled(false);
    const scrollTop = window.scrollY || document.body.scrollTop || window.pageYOffset;
    const bodyTop = document.body.getBoundingClientRect().top;
    const weekEls = document.getElementsByClassName('week');
    const navItems = document.getElementsByClassName('week-nav__item');
    Array.prototype.forEach.call(weekEls, (el, i) => {
      const elTop = el.getBoundingClientRect().top - bodyTop;
      const topOffset = 90;
      if (scrollTop >= elTop - topOffset) {
        Array.prototype.forEach.call(navItems, (item) => {
          item.classList.remove('is-current');
        });
        if (!scrolledToBottom()) {
          return __guard__(navItems[i], x => x.classList.add('is-current'));
        }
        return __guard__(navItems[navItems.length - 1], x1 => x1.classList.add('is-current'));
      }
    });
  }, 150), [props.weeks]);

  useEffect(() => {
    window.addEventListener('scroll', handleScroll);
    return () => {
      window.removeEventListener('scroll', handleScroll);
    };
  }, [handleScroll]);

  const tooManyWeeks = () => {
    const nonEmptyWeeks = props.week_meetings.filter(week => week.length > 0);
    return nonEmptyWeeks.length < props.weeks.length;
  };

  if (props.loading) {
    return <Loading />;
  }

  const weekComponents = [];
  const weeksBeforeTimeline = CourseDateUtils.weeksBeforeTimeline(props.course);
  const usingCustomTitlesFlag = usingCustomTitles();
  const weekNavInfo = [];

  props.weeks.sort((a, b) => a.order - b.order);

  let tooManyWeeksWarning;
  if (tooManyWeeks()) {
    tooManyWeeksWarning = (
      <li className="timeline-warning">
        WARNING! There are not enough non-holiday weeks before the assignment end date! You can click &apos;Edit Course Dates&apos; to set the meeting dates and holiday dates.
      </li>
    );
  }

  props.allWeeks.forEach((week, index) => {
    const weekAnchorName = `week-${index + 1 + weeksBeforeTimeline}`;
    if (week.empty) {
      const emptyWeekKey = `empty-week-${index}`;
      weekNavInfo.push({ emptyWeek: true, title: undefined });
      weekComponents.push(
        <div key={emptyWeekKey}>
          <a className="timeline__anchor" name={weekAnchorName} />
          <EmptyWeek
            course={props.course}
            edit_permissions={props.edit_permissions}
            index={index + 1}
            usingCustomTitles={usingCustomTitlesFlag}
            timeline_start={props.course.timeline_start}
            timeline_end={props.course.timeline_end}
            weeksBeforeTimeline={weeksBeforeTimeline}
            addWeek={props.addWeek}
          />
        </div>
      );
    } else {
      weekNavInfo.push({ emptyWeek: false, title: week.title });
      weekComponents.push(
        <div key={week.id}>
          <a className="timeline__anchor" name={weekAnchorName} />
          <Week
            week={week}
            index={index + 1}
            reorderable={props.reorderable}
            editableTitles={props.editableTitles}
            usingCustomTitles={usingCustomTitlesFlag}
            updateTitle={props.updateTitle}
            blocks={week.blocks}
            deleteWeek={() => deleteWeek(week.id)}
            meetings={week.meetings}
            timeline_start={props.course.timeline_start}
            timeline_end={props.course.timeline_end}
            all_training_modules={props.all_training_modules}
            editableBlockIds={props.editableBlockIds}
            edit_permissions={props.edit_permissions}
            saveBlockChanges={props.saveBlockChanges}
            setBlockEditable={props.setBlockEditable}
            cancelBlockEditable={props.cancelBlockEditable}
            updateBlock={props.updateBlock}
            addBlock={props.addBlock}
            deleteBlock={props.deleteBlock}
            saveGlobalChanges={props.saveGlobalChanges}
            canBlockMoveUp={canBlockMoveUp.bind(this, week, (week.order - 1))}
            canBlockMoveDown={canBlockMoveDown.bind(this, week, (week.order - 1))}
            onMoveBlockUp={handleMoveBlock.bind(this, true)}
            onMoveBlockDown={handleMoveBlock.bind(this, false)}
            onBlockDrag={(targetIndex, block, target) => {
              const originalIndexCheck = getBlocksInWeek(block.week_id).indexOf(block);
              if (originalIndexCheck !== targetIndex || block.week_id !== target.week_id) {
                return moveBlock(block, target.week_id, targetIndex);
              }
            }}
            weeksBeforeTimeline={weeksBeforeTimeline}
          />
        </div>
      );
    }
  });

  const weekNavs = weekNavInfo.map((weekInfo, index) => {
    let weekNav;
    if (weekInfo.emptyWeek) {
      weekNav = (
        <li className="week-nav__item is-empty" key={`week-${index + 1}-nav`}>
          {I18n.t('timeline.empty_week')}
        </li>
      );
    } else {
      let title;
      if (usingCustomTitlesFlag) {
        title = weekInfo.title || `${I18n.t('timeline.week')} ${index + 1}`;
      } else {
        title = `${I18n.t('timeline.week')} ${index + 1}`;
      }
      weekNav = (
        <li className="week-nav__item" key={`week-${index + 1}-nav`}>
          <a href={`#week-${index + 1}`}>{title}</a>
        </li>
      );
    }
    return weekNav;
  });

  const addWeekButton = props.edit_permissions ? (
    <button onClick={addWeek} className="week__add-week button dark small">Add Week</button>
  ) : null;

  const deleteAllWeeksButton = props.edit_permissions ? (
    <button onClick={deleteAllWeeks} className="week__delete-all-weeks button dark small">Delete All Weeks</button>
  ) : null;

  return (
    <div className="timeline">
      <Affix offset={90}>
        <div className="week-nav">
          <ul>
            {weekNavs}
            {tooManyWeeksWarning}
            <li className="week-nav__add-week">{addWeekButton}</li>
            <li className="week-nav__delete-all-weeks">{deleteAllWeeksButton}</li>
          </ul>
        </div>
      </Affix>
      <div className="timeline__body">
        {weekComponents}
      </div>
    </div>
  );
};

Timeline.propTypes = {
  loading: PropTypes.bool,
  weeks: PropTypes.array.isRequired,
  allWeeks: PropTypes.array.isRequired,
  week_meetings: PropTypes.array.isRequired,
  edit_permissions: PropTypes.bool,
  addWeek: PropTypes.func.isRequired,
  deleteWeek: PropTypes.func.isRequired,
  deleteAllWeeks: PropTypes.func.isRequired,
  reorderable: PropTypes.bool,
  editableTitles: PropTypes.bool,
  updateTitle: PropTypes.func,
  course: PropTypes.object.isRequired,
  all_training_modules: PropTypes.array.isRequired,
  editableBlockIds: PropTypes.array.isRequired,
  saveBlockChanges: PropTypes.func.isRequired,
  setBlockEditable: PropTypes.func.isRequired,
  cancelBlockEditable: PropTypes.func.isRequired,
  updateBlock: PropTypes.func.isRequired,
  addBlock: PropTypes.func.isRequired,
  deleteBlock: PropTypes.func.isRequired,
  saveGlobalChanges: PropTypes.func.isRequired,
  insertBlock: PropTypes.func.isRequired,
};

export default EditableRedux(Timeline);

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}
