# Requirements
#----------------------------------------

React             = require 'react'
NotificationStore = require '../../stores/notification_store.coffee'
NotificationActions = require('../../actions/notification_actions.js').default


# Component
#----------------------------------------

Notifications = React.createClass(

  mixins: [NotificationStore.mixin]

  getInitialState: ->
    notifications: NotificationStore.getNotifications()

  storeDidChange: ->
    @setState
      notifications: NotificationStore.getNotifications()

  _handleClose: (notification) ->
    NotificationActions.removeNotification(notification)

  _renderNotification: (notification, i) ->
    if notification.type is "error"
      message = (
        <p>
          <strong>There was an error:</strong> {notification.message}
        </p>
      )
    else
      message = notification.message

    if notification.closable
      closeIcon = (
        <svg tabIndex="0" onClick={@_handleClose.bind(this, notification)} viewBox="0 0 24 24" preserveAspectRatio="xMidYMid meet" style={{"fill":"currentcolor", "verticalAlign": "middle", "width":"32px", "height":"32px"}}><g><path d="M19 6.41l-1.41-1.41-5.59 5.59-5.59-5.59-1.41 1.41 5.59 5.59-5.59 5.59 1.41 1.41 5.59-5.59 5.59 5.59 1.41-1.41-5.59-5.59z"></path></g></svg>
      )

    <div key={i} className='notice'>
      <div className='container'>
        {message}
        {closeIcon}
      </div>
    </div>

  render: ->
    notifications = @state.notifications.map (n, i) => @_renderNotification(n, i)

    <div className="notifications">
      {notifications}
    </div>
)

# Exports
#----------------------------------------

module.exports = Notifications
