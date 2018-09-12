import { RECEIVE_TIMELINE, ADD_WEEK, DELETE_WEEK } from '../constants';

const initialState = {
  blocks: {},
  blocksPersisted: {},
  weeks: {},
  weeksPersisted: {},
  loading: true
};

const newWeek = (tempId, state) => ({
  id: tempId,
  is_new: true, // remove ids from objects with is_new when persisting
  blocks: [],
  order: Object.keys(state.weeks).length + 1
});

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

export default function timeline(state = initialState, action) {
  switch (action.type) {
    case RECEIVE_TIMELINE: {
      const weeks = weeksFromTimeline(action.data);
      const blocks = blocksFromTimeline(action.data);
      return {
        ...state,
        weeks,
        weeksPersisted: { ...weeks },
        blocks,
        blocksPersisted: { ...blocks },
        loading: false
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
    default:
      return state;
  }
}
