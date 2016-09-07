# Requirements
#----------------------------------------

McFly = require 'mcfly'
Flux = new McFly()
CourseStore = require './course_store.coffee'
ServerActions     = require('../actions/server_actions.js').default

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
    when 'API_FAIL', 'SAVE_TIMELINE_FAIL'
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

      if payload.actionType == 'SAVE_TIMELINE_FAIL'
        course_id = CourseStore.getCourse().slug
        ServerActions.fetch 'course', course_id
        ServerActions.fetch 'timeline', course_id
        notification.message = 'The changes you just submitted were not saved. ' +
                               'This may happen if the timeline has been changed — ' +
                               'by someone else, or by you in another browser ' +
                               'window — since the page was loaded. The latest ' +
                               'course data has been reloaded, and is ready for ' +
                               'you to edit further.'

      addNotification(notification)
      break

  return true


# Exports
#----------------------------------------

module.exports = NotificationStore
