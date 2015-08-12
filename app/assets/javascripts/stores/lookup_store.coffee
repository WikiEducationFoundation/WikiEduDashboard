McFly           = require 'mcfly'
Flux            = new McFly()
ServerActions   = require '../actions/server_actions'


# Data
_lookups = {}


# Utilities
addLookups = (key, values) ->
  _lookups[key] = values
  LookupStore.emitChange()


# Store
LookupStore = Flux.createStore
  getLookups: (model) ->
    if _lookups.hasOwnProperty(model)
      _lookups[model]
    else
      ServerActions.fetchLookups(model)
      []
, (payload) ->
  data = payload.data
  switch(payload.actionType)
    when 'RECEIVE_LOOKUPS'
      addLookups(data.model, data.values)
      break
  if payload.actionType.indexOf("RECEIVE") > 0
    model = (payload.actionType.match(/RECEIVE_(.*?)S/))[1].toLowerCase()
    ServerActions.fetchLookups model if model in Object.keys(_lookups)
  return true

LookupStore.setMaxListeners(0)

module.exports = LookupStore