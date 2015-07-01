McFly           = require 'mcfly'
Flux            = new McFly()


# Data
_validations = {}
_errorQueue = []


# Utilities
setValidation = (key, valid, message, changed=true, quiet=false) ->
  if !valid && changed && !(key in _errorQueue) # key is invalid
    _errorQueue.push key
  else if valid && key in _errorQueue
    _errorQueue.splice(_errorQueue.indexOf(key), 1)
  _validations[key] =
    valid: valid
    changed: changed
    message: message
  ValidationStore.emitChange() unless quiet


# Store
ValidationStore = Flux.createStore
  isValid: ->
    valid = true
    for key in Object.keys(_validations)
      if !_validations[key].changed && !_validations[key].valid
        setValidation(key, false, _validations[key].message, true)
      valid = valid && _validations[key].valid
    return valid
  getValidations: ->
    _validations
  getValidation: (key) ->
    if _validations[key]? && _validations[key].changed
      _validations[key].valid
    else true
  firstMessage: ->
    if _errorQueue.length > 0
      _validations[_errorQueue[0]]
    else
      null
, (payload) ->
  data = payload.data
  switch(payload.actionType)
    when 'INITIALIZE'
      if !_validations[data.key]?
        setValidation(data.key, false, data.message, false, true)
      break
    when 'SET_VALID'
      setValidation(data.key, true, null, true, data.quiet)
      break
    when 'SET_INVALID'
      setValidation(data.key, false, data.message, true, data.quiet)
      break
    when 'CHECK_SERVER'
      setValidation(data.key, !data.message?, data.message)
      break
  return true

ValidationStore.setMaxListeners(0)

module.exports = ValidationStore
