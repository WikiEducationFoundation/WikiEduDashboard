import McFly from 'mcfly';
const Flux = new McFly();
import _ from 'lodash';

import WeekStore from './week_store.js';

// Data
let _blocks = {};
const _persisted = {};
const _trainingModule = {};
let _editableBlockIds = [];
let _editingAddedBlock = false;

// Utilities
const setBlocks = function (data, persisted = false) {
  for (let j = 0; j < data.length; j++) {
    const week = data[j];
    for (let i = 0; i < week.blocks.length; i++) {
      const block = week.blocks[i];
      _blocks[block.id] = block;
      if (persisted) { _persisted[block.id] = $.extend(true, {}, block); }
    }
  }
  return BlockStore.emitChange();
};

const setBlock = function (data, quiet) {
  _blocks[data.id] = data;
  if (!quiet) { return BlockStore.emitChange(); }
};

const isAddedBlock = blockId =>
  // new block ids are set to Date.now()
  blockId > 1000000000;
const setEditableBlockId = function (blockId) {
  _editableBlockIds.push(blockId);
  if (isAddedBlock(blockId)) { _editingAddedBlock = true; }
  return BlockStore.emitChange();
};

const addBlock = function (weekId) {
  let weekBlocks = BlockStore.getBlocksInWeek(weekId);
  weekBlocks = $.grep(weekBlocks, block => !block.deleted);
  const block = {
    id: Date.now(),
    is_new: true,
    kind: 0,
    title: '',
    content: '',
    gradeable_id: null,
    week_id: weekId,
    order: weekBlocks.length,
    duration: null
  };
  setBlock(block);
  return setEditableBlockId(block.id);
};

const removeBlock = function (blockId) {
  delete _blocks[blockId];
  _editingAddedBlock = false;
  return BlockStore.emitChange();
};

const insertBlock = function (block, toWeek, targetIndex) {
  const fromWeekId = block.week_id;
  block.week_id = toWeek.id;

  if (targetIndex !== undefined) {
    if (toWeek.id === fromWeekId) {
      block.order = block.order > targetIndex ? targetIndex - 0.5 : targetIndex + 0.5;
    } else {
      const fromWeek = WeekStore.getWeek(fromWeekId);
      block.order = fromWeek.order > toWeek.order ? targetIndex + 999 : targetIndex - 0.5;
    }
  } else {
    block.order = -1;
  }

  setBlock(block, true);

  const fromWeekBlocks = BlockStore.getBlocksInWeek(fromWeekId);
  fromWeekBlocks.forEach((b, i) => {
    b.order = i;
    return setBlock(b, true);
  });

  if (fromWeekId !== toWeek.id) {
    const toWeekBlocks = BlockStore.getBlocksInWeek(toWeek.id);
    toWeekBlocks.forEach((b, i) => {
      b.order = i;
      return setBlock(b, true);
    });
  }
  return BlockStore.emitChange();
};

const storeMethods = {
  getBlock(blockId) {
    return _blocks[blockId];
  },
  getBlocks() {
    const blockList = [];
    const iterable = Object.keys(_blocks);
    for (let i = 0; i < iterable.length; i++) {
      const blockId = iterable[i];
      blockList.push(_blocks[blockId]);
    }
    return blockList;
  },
  getBlocksInWeek(weekId) {
    return _.filter(_blocks, block => block.week_id === weekId)
      .sort((a, b) => a.order - b.order);
  },
  restore() {
    _blocks = $.extend(true, {}, _persisted);
    _editingAddedBlock = false;
    return BlockStore.emitChange();
  },
  getTrainingModule() {
    return _trainingModule;
  },
  getEditableBlockIds() {
    return _editableBlockIds;
  },
  clearEditableBlockIds() {
    _editableBlockIds = [];
    return BlockStore.emitChange();
  },
  cancelBlockEditable(blockId) {
    _editableBlockIds.splice(_editableBlockIds.indexOf(blockId), 1);
    _editingAddedBlock = false;
    return BlockStore.emitChange();
  },
  editingAddedBlock() {
    return _editingAddedBlock;
  }
};


// Store
const BlockStore = Flux.createStore(storeMethods, (payload) => {
  const { data } = payload;
  switch (payload.actionType) {
    case 'RECEIVE_TIMELINE': case 'SAVED_TIMELINE': case 'WIZARD_SUBMITTED':
      _blocks = {};
      setBlocks(data.course.weeks, true);
      break;
    case 'ADD_BLOCK':
      addBlock(data.week_id);
      break;
    case 'UPDATE_BLOCK':
      setBlock(data.block, data.quiet);
      break;
    case 'DELETE_BLOCK':
      removeBlock(data.block_id);
      break;
    case 'INSERT_BLOCK':
      insertBlock(data.block, data.toWeek, data.afterBlock);
      break;
    case 'SET_BLOCK_EDITABLE':
      setEditableBlockId(data.block_id);
      break;
    default:
      // no default
  }
  return true;
});

export default BlockStore;
