// General purpose store covering typical use cases for several of our models
import McFly from 'mcfly';
const Flux = new McFly();
import _ from 'lodash';

function __in__(needle, haystack) {
  return haystack.indexOf(needle) >= 0;
}

const StockStore = function (helper, modelKey, defaultModel, triggers) {
  const pluralModelKey = `${modelKey}s`;
  const baseModel = () =>
    _.assign({
      id: Date.now(), // could THEORETICALLY collide but highly unlikely
      is_new: true // remove ids from objects with is_new when persisting
    }, defaultModel);
  return Flux.createStore(
    {
      getFiltered(options) {
        const filteredModels = [];
        const iterable = this.getModels();
        for (let i = 0; i < iterable.length; i++) {
          const model = iterable[i];
          let add = true;
          const iterable1 = Object.keys(options);
          for (let j = 0; j < iterable1.length; j++) {
            const criterion = iterable1[j];
            add = add && model[criterion] === options[criterion] && !model.deleted;
          }
          if (add) { filteredModels.push(model); }
        }
        return filteredModels;
      },

      clear() {
        helper.models = {};
        return this.emitChange();
      },

      getModels() {
        const modelList = [];
        const iterable = Object.keys(helper.models);
        for (let i = 0; i < iterable.length; i++) {
          const modelId = iterable[i];
          modelList.push(helper.models[modelId]);
        }
        let sorted = _.sortBy(modelList, helper.sortKey);
        if (!helper.sortAsc) { sorted = _(sorted).reverse().value(); }
        return sorted;
      },
      getSorting() {
        return {
          key: helper.sortKey,
          asc: helper.sortAsc
        };
      },
      isLoaded() {
        return helper.isLoaded();
      },
      restore() {
        helper.models = $.extend(true, {}, helper.persisted);
        return this.emitChange();
      }
    }
    , (payload) => {
      const { data } = payload;
      switch (payload.actionType) {
        case `RECEIVE_${pluralModelKey.toUpperCase()}`:
        case `${modelKey.toUpperCase()}_MODIFIED`:
          helper.setModels(data.course[pluralModelKey], true);
          break;
        case `SORT_${pluralModelKey.toUpperCase()}`:
          helper.sortByKey(data.key);
          break;
        case `ADD_${modelKey.toUpperCase()}`:
          helper.setModel(_.assign(data, baseModel()));
          break;
        case `UPDATE_${modelKey.toUpperCase()}`:
          helper.setModel(data[modelKey]);
          break;
        case `DELETE_${modelKey.toUpperCase()}`:
          helper.removeModel(data.model);
          break;
        default:
        // no default
      }
      if (triggers && __in__(payload.actionType, triggers)) {
        helper.setModels(data.course[pluralModelKey], true);
      }
      return true;
    }
  );
};

class Store {
  constructor(opts) {
    this.models = {};
    this.persisted = {};
    this.loaded = false;
    this.sortKey = opts.sortKey;
    this.sortAsc = opts.sortAsc;
    this.descKeys = opts.descKeys;
    this.uniqueKeys = opts.uniqueKeys || ['id'];
    this.store = StockStore(this, opts.modelKey, opts.defaultModel, opts.triggers);
    this.store.setMaxListeners(0);
  }

  // Utilities
  getKey(model) {
    return this.uniqueKeys.map(key => model[key]).join();
  }

  setModels(data, persisted = false) {
    this.loaded = true;
    this.models = {};
    if (persisted) { this.persisted = {}; }
    if (data.length > 0) {
      for (let i = 0; i < data.length; i++) {
        const model = data[i];
        this.models[this.getKey(model)] = model;
        if (persisted) { this.persisted[this.getKey(model)] = $.extend(true, {}, model); }
      }
    }
    return this.store.emitChange();
  }

  setModel(data) {
    this.models[this.getKey(data)] = data;
    return this.store.emitChange();
  }

  removeModel(model) {
    const modelId = this.getKey(model);
    if (model.is_new) {
      delete this.models[modelId];
    } else {
      model = this.models[modelId];
      model.deleted = true;
    }
    return this.store.emitChange();
  }

  sortByKey(key) {
    if (this.sortKey === key) {
      this.sortAsc = !this.sortAsc;
    } else {
      this.sortAsc = !this.descKeys[key];
      this.sortKey = key;
    }
    return this.store.emitChange();
  }

  getModels() {
    return this.store.getModels();
  }

  getSorting() {
    return this.store.getSorting();
  }

  isLoaded() {
    return this.loaded;
  }

  restore() {
    return this.store.restore();
  }
}

export default Store;
