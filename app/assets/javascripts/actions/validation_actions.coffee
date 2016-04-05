McFly       = require 'mcfly'
Flux        = new McFly()

ValidationActions = Flux.createActions
  initialize: (key, message) ->
    { actionType: 'INITIALIZE', data: {
      key: key,
      message: message
    }}
  setValid: (key, quiet=false) ->
    { actionType: 'SET_VALID', data: {
      key: key,
      quiet: quiet
    }}
  setInvalid: (key, message, quiet=false) ->
    { actionType: 'SET_INVALID', data: {
      key: key,
      message: message,
      quiet: quiet
    }}

module.exports = ValidationActions