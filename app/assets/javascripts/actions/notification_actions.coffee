McFly       = require 'mcfly'
Flux        = new McFly()

NotificationActions = Flux.createActions
  removeNotification: (notification) ->
    { actionType: 'REMOVE_NOTIFICATION', notification: notification }

module.exports = NotificationActions
