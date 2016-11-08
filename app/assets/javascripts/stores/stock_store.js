// General purpose store covering typical use cases for several of our models

import McFly from 'mcfly';
let Flux  = new McFly();

let StockStore = function(helper, model_key, default_model, triggers) {
  let plural_model_key = model_key + 's';
  let base_model = () =>
    _.assign({
      id: Date.now(), // could THEORETICALLY collide but highly unlikely
      is_new: true // remove ids from objects with is_new when persisting
    }, default_model)
  ;

  return Flux.createStore({
    getFiltered(options) {
      let filtered_models = [];
      let iterable = this.getModels();
      for (let i = 0; i < iterable.length; i++) {
        let model = iterable[i];
        let add = true;
        let iterable1 = Object.keys(options);
        for (let j = 0; j < iterable1.length; j++) {
          let criterion = iterable1[j];
          add = add && model[criterion] === options[criterion] && !model['deleted'];
        }
        if (add) { filtered_models.push(model); }
      }
      return filtered_models;
    },

    clear() {
      helper.models = {};
      return this.emitChange();
    },

    getModels() {
      let model_list = [];
      let iterable = Object.keys(helper.models);
      for (let i = 0; i < iterable.length; i++) {
        let model_id = iterable[i];
        model_list.push(helper.models[model_id]);
      }
      let sorted = _.sortBy(model_list, helper.sortKey);
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
  , function(payload) {
    let { data } = payload;
    switch(payload.actionType) {
      case `RECEIVE_${plural_model_key.toUpperCase()}`: case `${model_key.toUpperCase()}_MODIFIED`:
        helper.setModels(data.course[plural_model_key], true);
        break;
      case `SORT_${plural_model_key.toUpperCase()}`:
        helper.sortByKey(data.key);
        break;
      case `ADD_${model_key.toUpperCase()}`:
        helper.setModel(_.assign(data, base_model()));
        break;
      case `UPDATE_${model_key.toUpperCase()}`:
        helper.setModel(data[model_key]);
        break;
      case `DELETE_${model_key.toUpperCase()}`:
        helper.removeModel(data['model']);
        break;
    }
    if ((triggers != null) && __in__(payload.actionType, triggers)) {
      helper.setModels(data.course[plural_model_key], true);
    }
    return true;
  });
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
    return this.uniqueKeys.map(key => model[key]
    ).join();
  }

  setModels(data, persisted=false) {
    this.loaded = true;
    this.models = {};
    if (persisted) { this.persisted = {}; }
    if (data.length > 0) {
      for (let i = 0; i < data.length; i++) {
        let model = data[i];
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
    let model_id = this.getKey(model);
    if (model.is_new) {
      delete this.models[model_id];
    } else {
      model = this.models[model_id];
      model['deleted'] = true;
    }
    return this.store.emitChange();
  }

  sortByKey(key) {
    if (this.sortKey === key) {
      this.sortAsc = !this.sortAsc;
    } else {
      this.sortAsc = !(this.descKeys[key] != null);
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

function __in__(needle, haystack) {
  return haystack.indexOf(needle) >= 0;
}