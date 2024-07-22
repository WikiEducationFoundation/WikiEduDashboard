import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import { useTranslation } from 'react-i18next';
import Block from './block.jsx';
import DateCalculator from '../../utils/date_calculator.js';
import SpringBlock from './SpringBlock';
import BlockList from './BlockList';

const Week = (props) => {
  const {
    week,
    index,
    timeline_start,
    timeline_end,
    meetings,
    blocks,
    edit_permissions,
    editableBlockIds,
    reorderable,
    editableTitles,
    updateTitle,
    saveBlockChanges,
    cancelBlockEditable,
    addBlock,
    deleteWeek,
    all_training_modules,
    weeksBeforeTimeline,
    trainingLibrarySlug,
    current_user,
    deleteBlock,
    setBlockEditable,
    updateBlock,
    moveBlock,
  } = props;

  const { t } = useTranslation();

  const [focusedBlockId, setFocusedBlockId] = useState(null);
  const [isHover, setIsHover] = useState(false);

  useEffect(() => {
    const hash = window.location.hash.substring(1);
    const weekNo = weekNumber();
    if (hash === `week-${weekNo}`) {
      const weekElement = document.getElementsByName(hash)[0];
      if (weekElement) weekElement.scrollIntoView();
    }
  }, []);

  const handleMouseEnter = () => setIsHover(true);
  const handleMouseLeave = () => setIsHover(false);

  const handleAddBlock = () => {
    scrollToAddedBlock();
    addBlock(week.id);
  };

  const toggleFocused = (blockId) => {
    setFocusedBlockId(focusedBlockId === blockId ? null : blockId);
  };

  const scrollToAddedBlock = () => {
    const weekElement = document.getElementsByClassName(`week-${index}`)[0];
    if (weekElement) {
      const scrollTop = window.scrollY || document.body.scrollTop;
      const bottom = weekElement.getBoundingClientRect().bottom;
      const elBottom = bottom + scrollTop - 50;
      window.scrollTo({ top: elBottom, behavior: 'smooth' });
    }
  };

  const weekNumber = () => index + weeksBeforeTimeline;

  const dateCalc = new DateCalculator(timeline_start, timeline_end, index, { zeroIndexed: false });

  const weekDatesContent = meetings
    ? `${dateCalc.start()} - ${dateCalc.end()}`
    : `Week of ${dateCalc.start()} — ${t('AFTER_TIMELINE_END_DATE')}`;

  const meetDatesDiv = meetings && meetings.length > 0 && (
    <div className="margin-bottom">
      {t('Meetings')}: {meetings.join(', ')}
    </div>
  );

  const weekTitleContent = week.title || `${t('Week')} ${weekNumber()}`;

  const weekId = week.id;
  const weekTitle = editableTitles ? (
    <input
      className="week-index week-title-input"
      defaultValue={weekTitleContent}
      maxLength={20}
      onChange={(event) => updateTitle(weekId, event.target.value)}
    />
  ) : (
    <h2 className="week-index">
      {weekTitleContent}
      <span className="week-range"> ({weekDatesContent})</span>
    </h2>
  );

  blocks.sort((a, b) => a.order - b.order);

  const blockComponents = blocks.map((block, i) => (
    reorderable ? (
      <SpringBlock block={block} i={i} key={block.id} toggleFocused={toggleFocused} {...props} />
    ) : (
      <Block
        toggleFocused={() => toggleFocused(block.id)}
        block={block}
        key={block.id}
        editPermissions={edit_permissions}
        deleteBlock={deleteBlock}
        week_index={index}
        weekStart={dateCalc.startDate()}
        all_training_modules={all_training_modules}
        editableBlockIds={editableBlockIds}
        saveBlockChanges={saveBlockChanges}
        setBlockEditable={setBlockEditable}
        cancelBlockEditable={cancelBlockEditable}
        updateBlock={updateBlock}
        trainingLibrarySlug={trainingLibrarySlug}
        current_user={current_user}
      />
    )
  ));

  const addBlockButton = !reorderable && (
    <button className="pull-right week__add-block" onClick={handleAddBlock}>
      {t('Add Block')} <span className="icon-plus-blue" />
    </button>
  );

  const deleteWeekButton = !reorderable && !week.is_new && (
    <button
      onMouseEnter={handleMouseEnter}
      onMouseLeave={handleMouseLeave}
      className="pull-right week__delete-week"
      onClick={deleteWeek}
    >
      {t('Delete Week')} <span className={isHover ? 'icon-trash_can-hover' : 'icon-trash_can'} />
    </button>
  );

  const weekAddDelete = edit_permissions && (
    <div className="week__week-add-delete pull-right">
      {addBlockButton}
      {deleteWeekButton}
    </div>
  );

  const weekContent = reorderable ? (
    <BlockList blocks={blocks} week_id={week.id} moveBlock={moveBlock} {...props} />
  ) : (
    <ul className="week__block-list list-unstyled">
      {blockComponents}
    </ul>
  );

  const weekClassName = `week week-${index}${!meetings ? ' timeline-warning' : ''}`;

  return (
    <li className={weekClassName}>
      <div className="week__week-header">
        {weekAddDelete}
        {weekTitle}
        {meetDatesDiv}
      </div>
      {weekContent}
    </li>
  );
};

Week.propTypes = {
  week: PropTypes.object,
  index: PropTypes.number,
  timeline_start: PropTypes.string,
  timeline_end: PropTypes.string,
  meetings: PropTypes.array,
  blocks: PropTypes.array,
  edit_permissions: PropTypes.bool,
  editableBlockIds: PropTypes.array,
  reorderable: PropTypes.bool,
  editableTitles: PropTypes.bool,
  updateTitle: PropTypes.func,
  saveBlockChanges: PropTypes.func,
  cancelBlockEditable: PropTypes.func,
  addBlock: PropTypes.func,
  deleteWeek: PropTypes.func,
  all_training_modules: PropTypes.array,
  weeksBeforeTimeline: PropTypes.number,
  trainingLibrarySlug: PropTypes.string.isRequired,
  current_user: PropTypes.object,
  deleteBlock: PropTypes.func,
  setBlockEditable: PropTypes.func,
  updateBlock: PropTypes.func,
  moveBlock: PropTypes.func,
};

export default Week;
