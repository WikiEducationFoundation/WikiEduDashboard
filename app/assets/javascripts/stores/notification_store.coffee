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
  getNotifications: ->
    return _notifications
, (payload) ->
  switch(payload.actionType)
    when 'REMOVE_NOTIFICATION'
      removeNotification(payload.notification)
    when 'API_FAIL'
      data = payload.data
      notification = {}
      notification.closable = true
      notification.type = "error"
      if data.responseJSON and data.responseJSON.error
        notification.message = data.responseJSON.error
      else
        notification.message = data.statusText
      addNotification(notification)
      break
  return true


# Exports
#----------------------------------------

module.exports = NotificationStore
