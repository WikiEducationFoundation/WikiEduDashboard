import {
  RECEIVE_TIMELINE,
  SAVED_TIMELINE,
  ADD_WEEK,
  DELETE_WEEK,
  SET_BLOCK_EDITABLE,
  CANCEL_BLOCK_EDITABLE,
  UPDATE_BLOCK,
  ADD_BLOCK
} from '../constants';

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
  blockIds.forEach(blockId => {
    if (blocks[blockId].week_id === weekId) {
      count += 1;
    }
  });
  return count;
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

const weeksFromTimeline = data => {
  const weeks = {};
  data.course.weeks.forEach(week => {
    weeks[week.id] = week;
  });
  return weeks;
};

const blocksFromTimeline = data => {
  const blocks = {};
  data.course.weeks.forEach(week => {
    week.blocks.forEach(block => {
      blocks[block.id] = block;
    });
  });
  return blocks;
};

const removeBlockId = (blockIdsArray, blockId) => {
  const newArray = [];
  blockIdsArray.forEach(id => {
    if (id !== blockId) {
      newArray.push(id);
    }
  });
  return newArray;
};

export default function timeline(state = initialState, action) {
  switch (action.type) {
    case SAVED_TIMELINE:
    case RECEIVE_TIMELINE: {
      const weeks = weeksFromTimeline(action.data);
      const blocks = blocksFromTimeline(action.data);
      return {
        ...state,
        weeks,
        weeksPersisted: { ...weeks },
        blocks,
        blocksPersisted: { ...blocks },
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
      const updatedWeeks = { ...state.weeks };
      delete updatedWeeks[action.weekId];
      return { ...state, weeks: updatedWeeks };
    }
    case SET_BLOCK_EDITABLE: {
      return { ...state, editableBlockIds: [...state.editableBlockIds, action.blockId] };
    }
    case CANCEL_BLOCK_EDITABLE: {
      return { ...state, editableBlockIds: removeBlockId(state.editableBlockIds, action.blockId) };
    }
    case UPDATE_BLOCK: {
      const updatedBlocks = { ...state.blocks };
      updatedBlocks[action.block.id] = action.block;
      return { ...state, blocks: updatedBlocks };
    }
    case ADD_BLOCK: {
      const updatedBlocks = { ...state.blocks };
      updatedBlocks[action.tempId] = newBlock(action.tempId, action.weekId, state);
      return { ...state, blocks: updatedBlocks, editableBlockIds: [...state.editableBlockIds, action.tempId] };
    }
    default:
      return state;
  }
}
