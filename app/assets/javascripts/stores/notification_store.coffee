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


# Store
#----------------------------------------

NotificationStore = Flux.createStore
  getNotifications: ->
    return _notifications
, (payload) ->
  data = payload.data
  switch(payload.actionType)
    when 'API_FAIL'
      notification = {}
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
