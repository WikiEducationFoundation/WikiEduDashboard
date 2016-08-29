# Requirements
#----------------------------------------

McFly = require 'mcfly'
Flux = new McFly()

# Data
#----------------------------------------

_notifications = []


# Private Methods
#----------------------------------------

addNotification = (notification) ->
  _notifications.push(notification)
  NotificationStore.emitChange()

removeNotification = (notification) ->
  _.pull(_notifications, notification)
  NotificationStore.emitChange()

# Store
#----------------------------------------

NotificationStore = Flux.createStore
  clearNotifications: ->
    _notifications.length = 0
  getNotifications: ->
    return _notifications
, (payload) ->
  switch(payload.actionType)
    when 'REMOVE_NOTIFICATION'
      removeNotification(payload.notification)
      break
    when 'ADD_NOTIFICATION'
      addNotification(payload.notification)
      break
    when 'API_FAIL'
      data = payload.data
      # readyState 0 usually indicates that the user navigated away before ajax
      # requests resolved. This is a benign error that should not cause a notification.
      if data.readyState == 0
        return
      notification = {}
      notification.closable = true
      notification.type = "error"
      if data.responseText
        try
          notification.message = JSON.parse(data.responseText)['message']
        catch

      if data.responseJSON and data.responseJSON.error
        notification.message ||= data.responseJSON.error

      notification.message ||= data.statusText
      addNotification(notification)
      break

  return true


# Exports
#----------------------------------------

module.exports = NotificationStore
