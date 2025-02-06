import {
  RECEIVE_TIMELINE,
  SAVED_TIMELINE,
  ADD_WEEK,
  DELETE_WEEK,
  SET_BLOCK_EDITABLE,
  CANCEL_BLOCK_EDITABLE,
  UPDATE_BLOCK,
  ADD_BLOCK,
  DELETE_BLOCK,
  INSERT_BLOCK,
  UPDATE_TITLE,
  RESET_TITLES,
  RESTORE_TIMELINE,
  EXERCISE_COMPLETION_UPDATE
} from '../constants';
import { produce } from 'immer';

const initialState = {
  blocks: {},
  blocksPersisted: {},
  weeks: {},
  weeksPersisted: {},
  editableBlockIds: [],
  loading: true
};

const newWeek = (tempId, state) => ({
  id: tempId,
  is_new: true, // remove ids from objects with is_new when persisting
  blocks: [],
  order: Object.keys(state.weeks).length + 1
});

const blocksInWeek = (blocks, weekId) => {
  let count = 0;
  const blockIds = Object.keys(blocks);
  blockIds.forEach((blockId) => {
    if (blocks[blockId].week_id === weekId) {
      count += 1;
    }
  });
  return count;
};

const validateTitle = (title) => {
  return title.length <= 20;
};

const deepCopyWeeks = (weeks) => {
  const weeksCopy = {};
  const weekIds = Object.keys(weeks);
  weekIds.forEach((id) => {
    weeksCopy[id] = { ...weeks[id] };
  });
  return weeksCopy;
};

const newBlock = (tempId, weekId, state) => {
  return {
    id: tempId,
    is_new: true,
    kind: 0,
    title: '',
    content: '',
    week_id: weekId,
    order: blocksInWeek(state.blocks),
    duration: null,
    points: null
  };
};

const weeksFromTimeline = (data) => {
  const weeks = {};
  data.course.weeks.forEach((week) => {
    weeks[week.id] = { ...week };
  });
  return weeks;
};

const blocksFromTimeline = (data) => {
  const blocks = {};
  data.course.weeks.forEach((week) => {
    week.blocks.forEach((block) => {
      blocks[block.id] = { ...block };
    });
  });
  return blocks;
};

const removeBlockId = (blockIdsArray, blockId) => {
  const newArray = [];
  blockIdsArray.forEach((id) => {
    if (id !== blockId) {
      newArray.push(id);
    }
  });
  return newArray;
};

// Returns a new blocks object with updates to a single block's week and order within
// that week, along with updated order for any other blocks affected by the move.
const updateBlockPosition = (movingBlock, newWeekId, targetIndex, blocks) => {
  const oldWeekId = movingBlock.id;
  const movedBlock = { ...movingBlock };
  movedBlock.week_id = newWeekId;
  const weekChanged = newWeekId !== oldWeekId;
  const updatedBlocks = { ...blocks };

  // Remove the updated block, so that we can calculate the relative order of the
  // remaining blocks.
  delete updatedBlocks[movingBlock.id];

  // We only care about blocks in the week(s) the moved block is going
  // from or to. Collect those into arrays for sorting.
  const blocksInOldWeek = [];
  const blocksInNewWeek = [];
  // The moved block in not included in updatedBlocks, only the
  // other blocks from the week that the moved block is going to be inserted
  // into or removed from.
  Object.keys(updatedBlocks).forEach((blockId) => {
    const block = blocks[blockId];
    if (block.week_id === newWeekId) {
      blocksInNewWeek.push(block);
    }
    if (!weekChanged) { return; }
    if (block.week_id === oldWeekId) {
      blocksInOldWeek.push(block);
    }
  });

  // Sort the unmoved blocks in the affected weeks by block order.
  blocksInOldWeek.sort((a, b) => a.order - b.order);
  blocksInNewWeek.sort((a, b) => a.order - b.order);

  // Insert the moved block into the desired position in the target week.
  blocksInNewWeek.splice(targetIndex, 0, movedBlock);

  // Now, replace all the affected blocks with cloned objects,
  // with the order based on the sorting index.
  blocksInOldWeek.forEach((block, i) => {
    const updatedBlock = { ...block, order: i };
    updatedBlocks[block.id] = updatedBlock;
  });
  blocksInNewWeek.forEach((block, i) => {
    const updatedBlock = { ...block, order: i };
    updatedBlocks[block.id] = updatedBlock;
  });

  return updatedBlocks;
};


export default function timeline(state = initialState, action) {
  switch (action.type) {
    case SAVED_TIMELINE:
    case RECEIVE_TIMELINE: {
      return {
        ...state,
        weeks: weeksFromTimeline(action.data),
        weeksPersisted: weeksFromTimeline(action.data),
        blocks: blocksFromTimeline(action.data),
        blocksPersisted: blocksFromTimeline(action.data),
        loading: false,
        editableBlockIds: []
      };
    }
    case ADD_WEEK: {
      const updatedWeeks = { ...state.weeks };
      updatedWeeks[action.tempId] = newWeek(action.tempId, state);
      return { ...state, weeks: updatedWeeks };
    }
    case DELETE_WEEK: {
      const weeks = { ...state.weeks };
      const persistedWeeks = { ...state.persistedWeeks };
      delete weeks[action.weekId];
      delete persistedWeeks[action.weekId];
      return { ...state, weeks, persistedWeeks };
    }
    case SET_BLOCK_EDITABLE: {
      return { ...state, editableBlockIds: [...state.editableBlockIds, action.blockId] };
    }
    case CANCEL_BLOCK_EDITABLE: {
      const canceledBlock = { ...state.blocksPersisted[action.blockId] };
      const blocks = { ...state.blocks };
      blocks[action.blockId] = canceledBlock;
      return { ...state, blocks, editableBlockIds: removeBlockId(state.editableBlockIds, action.blockId) };
    }
    case UPDATE_BLOCK: {
      const updatedBlocks = { ...state.blocks };
      updatedBlocks[action.block.id] = action.block;
      return { ...state, blocks: updatedBlocks };
    }
    case ADD_BLOCK: {
      const blocks = { ...state.blocks };
      blocks[action.tempId] = newBlock(action.tempId, action.weekId, state);
      return { ...state, blocks, editableBlockIds: [...state.editableBlockIds, action.tempId] };
    }
    case DELETE_BLOCK: {
      const blocks = { ...state.blocks };
      const persistedBlocks = { ...state.persistedBlocks };
      delete blocks[action.blockId];
      delete persistedBlocks[action.blockId];
      return { ...state, blocks, persistedBlocks, editableBlockIds: removeBlockId(state.editableBlockIds, action.blockId) };
    }
    case INSERT_BLOCK: {
      const blocks = updateBlockPosition(action.block, action.newWeekId, action.afterBlock, state.blocks);
      return { ...state, blocks };
    }
    case UPDATE_TITLE: {
      return produce(state, (draft) => {
        if (validateTitle(action.title)) {
          draft.weeks[action.weekId].title = action.title;
        }
      });
    }
    case RESET_TITLES: {
      return produce(state, (draft) => {
        Object.keys(draft.weeks).forEach((weekId) => {
            draft.weeks[weekId].title = '';
        });
      });
    }
    case RESTORE_TIMELINE: {
      return { ...state, blocks: { ...state.blocksPersisted }, weeks: deepCopyWeeks(state.weeksPersisted), editableBlockIds: [] };
    }
    case EXERCISE_COMPLETION_UPDATE: {
      const block = action.data;
      return {
        ...state,
        blocks: {
          ...state.blocks,
          [block.id]: block
        }
      };
    }
    default:
      return state;
  }
}
