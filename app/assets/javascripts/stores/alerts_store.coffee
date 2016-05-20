McFly       = require 'mcfly'
Flux        = new McFly()

_needHelpAlertSubmitting = false
_needHelpAlertCreated = false

needHelpAlertSubmitted = ->
  _needHelpAlertSubmitting = true
  AlertsStore.emitChange()

needHelpAlertCreated = ->
  _needHelpAlertSubmitting = false
  _needHelpAlertCreated = true
  AlertsStore.emitChange()

resetNeedHelpAlert = ->
  _needHelpAlertSubmitting = false
  _needHelpAlertCreated = false
  AlertsStore.emitChange()

AlertsStore = Flux.createStore
  getNeedHelpAlertSubmitting: ->
    return _needHelpAlertSubmitting
  getNeedHelpAlertSubmitted: ->
    return _needHelpAlertCreated
, (payload) ->
  data = payload.data
  switch(payload.actionType)
    when 'NEED_HELP_ALERT_SUBMITTED'
      needHelpAlertSubmitted()
      break
    when 'NEED_HELP_ALERT_CREATED'
      needHelpAlertCreated()
      break
    when 'RESET_NEED_HELP_ALERT'
      resetNeedHelpAlert()
      break

module.exports = AlertsStore
