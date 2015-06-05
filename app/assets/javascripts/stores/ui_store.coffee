McFly           = require 'mcfly'
Flux            = new McFly()


# Data
_open_key = null


# Utilities
setOpenKey = (key) ->
  if key == _open_key
    _open_key = null
  else
    _open_key = key
  UIStore.emitChange()


# Store
UIStore = Flux.createStore
  getOpenKey: ->
    _open_key
, (payload) ->
  data = payload.data
  switch(payload.actionType)
    when 'OPEN_KEY'
      setOpenKey(data.key)
      break
  return true

UIStore.setMaxListeners(0)

module.exports = UIStore