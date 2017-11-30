import McFly from 'mcfly';
const Flux = new McFly();
import BlockStore from './block_store.js';
import GradeableStore from './gradeable_store.js';


// Data
let _weeks = {};
const _persisted = {};
let _isLoading = true;


// Utilities
const setWeeks = function (data, persisted = false) {
  for (let i = 0; i < data.length; i++) {
    const week = data[i];
    _weeks[week.id] = week;
    if (persisted) { _persisted[week.id] = $.extend(true, {}, week); }
  }
  _isLoading = false;
  return WeekStore.emitChange();
};

const setWeek = function (data) {
  _weeks[data.id] = data;
  return WeekStore.emitChange();
};

const addWeek = () =>
  setWeek({
    id: Date.now(), // could THEORETICALLY collide but highly unlikely
    is_new: true, // remove ids from objects with is_new when persisting
    blocks: []
  });
const removeWeek = function (weekId) {
  delete _weeks[weekId];
  return WeekStore.emitChange();
};

const removeAllWeeks = function () {
  _weeks = {};
  return WeekStore.emitChange();
};

// Store
const WeekStore = Flux.createStore(
  {
    getLoadingStatus() {
      return _isLoading;
    },
    getWeek(weekId) {
      return _weeks[weekId];
    },
    getWeeks() {
      const weekList = [];
      const iterable = Object.keys(_weeks);
      for (let i = 0; i < iterable.length; i++) {
        const weekId = iterable[i];
        weekList.push(_weeks[weekId]);
      }
      return weekList;
    },
    restore() {
      _weeks = $.extend(true, {}, _persisted);
      return WeekStore.emitChange();
    },
  }
  , (payload) => {
    const { data } = payload;
    switch (payload.actionType) {
      case 'RECEIVE_TIMELINE': case 'SAVED_TIMELINE': case 'WIZARD_SUBMITTED':
        Flux.dispatcher.waitFor([BlockStore.dispatcherID, GradeableStore.dispatcherID]);
        _weeks = {};
        setWeeks(data.course.weeks, true);
        break;
      case 'ADD_WEEK':
        addWeek();
        break;
      case 'DELETE_WEEK':
        removeWeek(data.week_id);
        break;
      case 'DELETE_ALL_WEEKS':
        removeAllWeeks();
        break;
      default:
      // no default
    }
    return true;
  }
);

export default WeekStore;
