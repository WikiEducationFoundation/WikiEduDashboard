# General purpose store covering typical use cases for several of our models

McFly           = require 'mcfly'
Flux            = new McFly()

StockStore = (helper, model_key, addModel) ->
  Flux.createStore
    getModels: ->
      model_list = []
      for model_id in Object.keys(helper.models)
        model_list.push helper.models[model_id]
      sorted = _.sortBy(model_list, helper.sortKey)
      sorted = _(sorted).reverse().value() unless helper.sortAsc
      return sorted
    getSorting: ->
      key: helper.sortKey
      asc: helper.sortAsc
    restore: ->
      helper.models = $.extend(true, {}, _persisted)
      @emitChange()
  , (payload) ->
    data = payload.data
    switch(payload.actionType)
      when 'RECEIVE_COURSE', 'RECEIVE_' + model_key.toUpperCase()
        helper.setModels data.course[model_key], true
      when 'SORT_' + model_key.toUpperCase()
        helper.sortByKey data.key
    return true

class Store
  constructor: (SortKey, SortAsc, DescKeys, ModelKey, AddModel) ->
    @models = {}
    @persisted = {}
    @sortKey = SortKey
    @sortAsc = SortAsc
    @descKeys = DescKeys
    @store = StockStore(@, ModelKey, AddModel)

  # Utilities
  setModels: (data, persisted=false) ->
    return unless data?
    for model, i in data
      @models[model.id] = model
      @persisted[model.id] = $.extend(true, {}, model) if persisted
    @store.emitChange()

  updatePersisted: ->
    for model_id in Object.keys(@models)
      @persisted[model_id] = $.extend(true, {}, @models[model_id])

  setModel: (data) ->
    @models[data.id] = data
    @store.emitChange()

  removeModel: (model_id) ->
    model = @models[model_id]
    if model.is_new
      delete @models[model_id]
    else
      model['deleted'] = true
    @store.emitChange()

  sortByKey: (key) ->
    if @sortKey == key
      @sortAsc = !@sortAsc
    else
      @sortAsc = !@descKeys[key]?
      @sortKey = key
    @store.emitChange()

  getModels: ->
    return @store.getModels()

  getSorting: ->
    @store.getSorting()

  restore: ->
    @store.restore()

module.exports = Store