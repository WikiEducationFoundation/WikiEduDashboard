McFly       = require 'mcfly'
Flux        = new McFly()

NotificationActions = Flux.createActions
  removeNotification: (notification) ->
    { actionType: 'REMOVE_NOTIFICATION', notification: notification }
  addNotification: (notification) ->
    { actionType: 'ADD_NOTIFICATION', notification: notification }

module.exports = NotificationActions
