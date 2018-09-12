import { RECEIVE_TIMELINE } from '../constants';

const initialState = {
  blocks: {},
  blocksPersisted: {},
  weeks: {},
  weeksPersisted: {},
  loading: true
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
    default:
      return state;
  }
}
