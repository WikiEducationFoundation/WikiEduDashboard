// import React, { useState } from 'react';

// import PropTypes from 'prop-types';
// import Block from './block.jsx';
// import DateCalculator from '../../utils/date_calculator.js';
// import SpringBlock from './SpringBlock';
// import BlockList from './BlockList';
// import { useEffect } from 'react';

// const Week = ({
//     week,
//     index,
//     timeline_start,
//     timeline_end ,
//     meetings,
//     blocks,
//     edit_permissions,
//     editableBlockIds,
//     reorderable,
//     editableTitles,
//     onBlockDrag,
//     onMoveBlockUp,
//     onMoveBlockDown,
//     usingCustomTitles,
//     updateTitle,
//     canBlockMoveUp,
//     canBlockMoveDown,
//     saveBlockChanges,
//     cancelBlockEditable,
//     addBlock,
//     deleteWeek,
//     all_training_modules,
//     weeksBeforeTimeline,
//     trainingLibrarySlug,
//     current_user
//   }) => {
//     // State for the focused block ID and hover state for delete button
//     const [focusedBlockId,setFocusedId] = useState(null);
//     const [isHover,setIsHover] = useState(false);
//      // Effect to scroll to the current week if the hash in the URL matches
//     useEffect(() => {
//       const hash = window.location.hash.substring(1);
//       const weekNo = weekNumber();
//       if (hash === `week-${weekNo}`) {
//         const weekElement = document.getElementsByName(hash)[0];
//         if (weekElement) weekElement.scrollIntoView();
//       }
//     }, []);
//   }
  
//   // Handlers for mouse enter and leave events
//   const handleMouseEnter = () => setIsHover(true);
//   const handleMouseLeave = () => setIsHover(false);

//   // Handler to add a new block and scroll to it
//   const handleAddBlock = () => {
//     scrollToAddedBlock();
//     addBlock(week.id);
//   };

//   // Toggle the focused state for a block
//   const toggleFocused = (blockId) => {
//     setFocusedBlockId(focusedBlockId === blockId ? null : blockId);
//   };
//   // Scroll smoothly to the newly added block
//   const scrollToAddedBlock = () => {
//     const weekElement = document.getElementsByClassName(`week-${index}`)[0];
//     if (weekElement) {
//       const scrollTop = window.scrollY || document.body.scrollTop;
//       const bottom = weekElement.getBoundingClientRect().bottom;
//       const elBottom = (bottom + scrollTop) - 50;
//       window.scrollTo({ top: elBottom, behavior: 'smooth' });
//     }
//   };

  
//   // Calculate the week number based on index and weeksBeforeTimeline
//   const weekNumber = () => index + weeksBeforeTimeline;

//   // Create a DateCalculator instance to handle date calculations
//   const dateCalc = new DateCalculator(timeline_start, timeline_end, index, { zeroIndexed: false });

//   // Generate content for week dates and meeting dates
//   const weekDatesContent = meetings
//     ? `${dateCalc.start()} - ${dateCalc.end()}`
//     : `Week of ${dateCalc.start()} — AFTER TIMELINE END DATE!`;

//   const meetDatesDiv = meetings && meetings.length > 0 && (
//     <div className="margin-bottom">
//       Meetings: {meetings.join(', ')}
//     </div>
//   );

//   // Set week title, defaulting to week number if no title is provided
//   const weekTitleContent = week.title || `Week ${weekNumber()}`;

//   // Conditionally render the week title as an input field if editable
//   const weekId = week.id;
//   const weekTitle = editableTitles ? (
//     <input
//       className="week-index week-title-input"
//       defaultValue={weekTitleContent}
//       maxLength={20}
//       onChange={(event) => updateTitle(weekId, event.target.value)}
//     />
//   ) : (
//     <h2 className="week-index">
//       {weekTitleContent}
//       <span className="week-range"> ({weekDatesContent})</span>
//     </h2>
//   );

//   // Sort blocks by their order property
//   blocks.sort((a, b) => a.order - b.order);

//   // Map blocks to their respective components, using SpringBlock if reorderable
//   const blockComponents = blocks.map((block, i) => (
//     reorderable ? (
//       <SpringBlock block={block} i={i} key={block.id} {...{ ...props, toggleFocused }} />
//     ) : (
//       <Block
//         toggleFocused={() => toggleFocused(block.id)}
//         block={block}
//         key={block.id}
//         editPermissions={edit_permissions}
//         deleteBlock={props.deleteBlock}
//         week_index={index}
//         weekStart={dateCalc.startDate()}
//         all_training_modules={all_training_modules}
//         editableBlockIds={editableBlockIds}
//         saveBlockChanges={saveBlockChanges}
//         setBlockEditable={props.setBlockEditable}
//         cancelBlockEditable={cancelBlockEditable}
//         updateBlock={props.updateBlock}
//         trainingLibrarySlug={trainingLibrarySlug}
//         current_user={current_user}
//       />
//     )
//   ));

//   // Conditionally render the add block button
//   const addBlockButton = !reorderable && (
//     <button className="pull-right week__add-block" onClick={handleAddBlock}>
//       Add Block <span className="icon-plus-blue" />
//     </button>
//   );

//   // Conditionally render the delete week button
//   const deleteWeekButton = !reorderable && !week.is_new && (
//     <button
//       onMouseEnter={handleMouseEnter}
//       onMouseLeave={handleMouseLeave}
//       className="pull-right week__delete-week"
//       onClick={deleteWeek}
//     >
//       Delete Week <span className={isHover ? 'icon-trash_can-hover' : 'icon-trash_can'} />
//     </button>
//   );

//   // Conditionally render the week add/delete controls
//   const weekAddDelete = edit_permissions && (
//     <div className="week__week-add-delete pull-right">
//       {addBlockButton}
//       {deleteWeekButton}
//     </div>
//   );

//   // Conditionally render the week content as a BlockList or an unordered list of blocks
//   const weekContent = reorderable ? (
//     <BlockList blocks={blocks} week_id={week.id} moveBlock={props.moveBlock} {...props} />
//   ) : (
//     <ul className="week__block-list list-unstyled">
//       {blockComponents}
//     </ul>
//   );

//   // Generate the CSS class name for the week, adding a warning class if no meetings
//   const weekClassName = `week week-${index}` + (!meetings ? ' timeline-warning' : '');

//   // Render the week component
//   return (
//     <li className={weekClassName}>
//       <div className="week__week-header">
//         {weekAddDelete}
//         {weekTitle}
//         {meetDatesDiv}
//       </div>
//       {weekContent}
//     </li>
//   );
// }

// // Define PropTypes for the Week component
// Week.propTypes = {
//   week: PropTypes.object,
//   index: PropTypes.number,
//   timeline_start: PropTypes.string,
//   timeline_end: PropTypes.string,
//   meetings: PropTypes.array,
//   blocks: PropTypes.array,
//   edit_permissions: PropTypes.bool,
//   editableBlockIds: PropTypes.array,
//   reorderable: PropTypes.bool,
//   editableTitles: PropTypes.bool,
//   onBlockDrag: PropTypes.func,
//   onMoveBlockUp: PropTypes.func,
//   onMoveBlockDown: PropTypes.func,
//   usingCustomTitles: PropTypes.bool,
//   updateTitle: PropTypes.func,
//   canBlockMoveUp: PropTypes.func,
//   canBlockMoveDown: PropTypes.func,
//   saveBlockChanges: PropTypes.func,
//   cancelBlockEditable: PropTypes.func,
//   addBlock: PropTypes.func,
//   deleteWeek: PropTypes.func,
//   all_training_modules: PropTypes.array,
//   weeksBeforeTimeline: PropTypes.number,
//   trainingLibrarySlug: PropTypes.string.isRequired,
//   current_user: PropTypes.object
// };

// export default Week;



import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import Block from './block.jsx';
import DateCalculator from '../../utils/date_calculator.js';
import SpringBlock from './SpringBlock';
import BlockList from './BlockList';

const Week = ({
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
  moveBlock
}) => {
  // State for the focused block ID and hover state for delete button
  const [focusedBlockId, setFocusedBlockId] = useState(null);
  const [isHover, setIsHover] = useState(false);

  // Effect to scroll to the current week if the hash in the URL matches
  useEffect(() => {
    const hash = window.location.hash.substring(1);
    const weekNo = weekNumber();
    if (hash === `week-${weekNo}`) {
      const weekElement = document.getElementsByName(hash)[0];
      if (weekElement) weekElement.scrollIntoView();
    }
  }, []);

  // Handlers for mouse enter and leave events
  const handleMouseEnter = () => setIsHover(true);
  const handleMouseLeave = () => setIsHover(false);

  // Handler to add a new block and scroll to it
  const handleAddBlock = () => {
    scrollToAddedBlock();
    addBlock(week.id);
  };

  // Toggle the focused state for a block
  const toggleFocused = (blockId) => {
    setFocusedBlockId(focusedBlockId === blockId ? null : blockId);
  };

  // Scroll smoothly to the newly added block
  const scrollToAddedBlock = () => {
    const weekElement = document.getElementsByClassName(`week-${index}`)[0];
    if (weekElement) {
      const scrollTop = window.scrollY || document.body.scrollTop;
      const bottom = weekElement.getBoundingClientRect().bottom;
      const elBottom = (bottom + scrollTop) - 50;
      window.scrollTo({ top: elBottom, behavior: 'smooth' });
    }
  };

  // Calculate the week number based on index and weeksBeforeTimeline
  const weekNumber = () => index + weeksBeforeTimeline;

  // Create a DateCalculator instance to handle date calculations
  const dateCalc = new DateCalculator(timeline_start, timeline_end, index, { zeroIndexed: false });

  // Generate content for week dates and meeting dates
  const weekDatesContent = meetings
    ? `${dateCalc.start()} - ${dateCalc.end()}`
    : `Week of ${dateCalc.start()} — AFTER TIMELINE END DATE!`;

  const meetDatesDiv = meetings && meetings.length > 0 && (
    <div className="margin-bottom">
      Meetings: {meetings.join(', ')}
    </div>
  );

  // Set week title, defaulting to week number if no title is provided
  const weekTitleContent = week.title || `Week ${weekNumber()}`;

  // Conditionally render the week title as an input field if editable
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

  // Sort blocks by their order property
  blocks.sort((a, b) => a.order - b.order);

  // Map blocks to their respective components, using SpringBlock if reorderable
  const blockComponents = blocks.map((block, i) => (
    reorderable ? (
      <SpringBlock block={block} i={i} key={block.id} {...{ toggleFocused, ...props }} />
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

  // Conditionally render the add block button
  const addBlockButton = !reorderable && (
    <button className="pull-right week__add-block" onClick={handleAddBlock}>
      Add Block <span className="icon-plus-blue" />
    </button>
  );

  // Conditionally render the delete week button
  const deleteWeekButton = !reorderable && !week.is_new && (
    <button
      onMouseEnter={handleMouseEnter}
      onMouseLeave={handleMouseLeave}
      className="pull-right week__delete-week"
      onClick={deleteWeek}
    >
      Delete Week <span className={isHover ? 'icon-trash_can-hover' : 'icon-trash_can'} />
    </button>
  );

  // Conditionally render the week add/delete controls
  const weekAddDelete = edit_permissions && (
    <div className="week__week-add-delete pull-right">
      {addBlockButton}
      {deleteWeekButton}
    </div>
  );

  // Conditionally render the week content as a BlockList or an unordered list of blocks
  const weekContent = reorderable ? (
    <BlockList blocks={blocks} week_id={week.id} moveBlock={moveBlock} {...props} />
  ) : (
    <ul className="week__block-list list-unstyled">
      {blockComponents}
    </ul>
  );

  // Generate the CSS class name for the week, adding a warning class if no meetings
  const weekClassName = `week week-${index}` + (!meetings ? ' timeline-warning' : '');

  // Render the week component
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
}

// Define PropTypes for the Week component
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
  moveBlock: PropTypes.func
};

export default Week;
