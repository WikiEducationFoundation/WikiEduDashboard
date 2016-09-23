# General purpose store covering typical use cases for several of our models

McFly = require 'mcfly'
Flux  = new McFly()

StockStore = (helper, model_key, default_model, triggers) ->
  plural_model_key = model_key + 's'
  base_model = ->
    _.assign({
      id: Date.now() # could THEORETICALLY collide but highly unlikely
      is_new: true # remove ids from objects with is_new when persisting
    }, default_model)

  Flux.createStore
    getFiltered: (options) ->
      filtered_models = []
      for model in @getModels()
        add = true
        for criterion in Object.keys(options)
          add = add && model[criterion] == options[criterion] && !model['deleted']
        filtered_models.push model if add
      return filtered_models

    clear: ->
      helper.models = {}
      @emitChange()

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
    isLoaded: ->
      helper.isLoaded()
    restore: ->
      helper.models = $.extend(true, {}, helper.persisted)
      @emitChange()
  , (payload) ->
    data = payload.data
    switch(payload.actionType)
      when "RECEIVE_#{plural_model_key.toUpperCase()}", "#{model_key.toUpperCase()}_MODIFIED"
        helper.setModels data.course[plural_model_key], true
      when 'SORT_' + plural_model_key.toUpperCase()
        helper.sortByKey data.key
      when 'ADD_' + model_key.toUpperCase()
        helper.setModel _.assign(data, base_model())
      when 'UPDATE_' + model_key.toUpperCase()
        helper.setModel data[model_key]
      when 'DELETE_' + model_key.toUpperCase()
        helper.removeModel data['model']
    if triggers? && payload.actionType in triggers
      helper.setModels data.course[plural_model_key], true
    return true

class Store
  constructor: (opts) ->
    @models = {}
    @persisted = {}
    @loaded = false
    @sortKey = opts.sortKey
    @sortAsc = opts.sortAsc
    @descKeys = opts.descKeys
    @uniqueKeys = opts.uniqueKeys || ['id']
    @store = StockStore(@, opts.modelKey, opts.defaultModel, opts.triggers)
    @store.setMaxListeners(0)

  # Utilities
  getKey: (model) ->
    @uniqueKeys.map((key) ->
      model[key]
    ).join()

  setModels: (data, persisted=false) ->
    @loaded = true
    @models = {}
    @persisted = {} if persisted
    if data.length > 0
      for model, i in data
        @models[@getKey(model)] = model
        @persisted[@getKey(model)] = $.extend(true, {}, model) if persisted
    @store.emitChange()

  setModel: (data) ->
    @models[@getKey(data)] = data
    @store.emitChange()

  removeModel: (model) ->
    model_id = @getKey(model)
    if model.is_new
      delete @models[model_id]
    else
      model = @models[model_id]
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

  isLoaded: ->
    @loaded

  restore: ->
    @store.restore()

module.exports = Store
