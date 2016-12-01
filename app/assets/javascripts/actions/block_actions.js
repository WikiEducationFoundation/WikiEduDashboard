import McFly from 'mcfly';
const Flux = new McFly();
import API from '../utils/api.js';

const BlockActions = Flux.createActions({
  addBlock(weekId) {
    return {
      actionType: 'ADD_BLOCK',
      data: {
        week_id: weekId
      }
    };
  },

  updateBlock(block, quiet = false) {
    return {
      actionType: 'UPDATE_BLOCK',
      data: {
        block,
        quiet
      }
    };
  },

  deleteBlock(blockId) {
    return API.deleteBlock(blockId)
      .then(data => {
        return {
          actionType: 'DELETE_BLOCK',
          data: {
            block_id: data.block_id
          }
        };
      })
      .catch(data => ({ actionType: 'API_FAIL', data }));
  },

  insertBlock(block, toWeek, afterBlock) {
    return {
      actionType: 'INSERT_BLOCK',
      data: {
        block,
        toWeek,
        afterBlock
      }
    };
  },

  setEditable(blockId) {
    return {
      actionType: 'SET_BLOCK_EDITABLE',
      data: {
        block_id: blockId
      }
    };
  }
});

export default BlockActions;
