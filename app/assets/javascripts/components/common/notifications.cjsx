# Requirements
#----------------------------------------

React = require 'react'


# Component
#----------------------------------------

Notifications = React.createClass(
  render: ->
    notifications = []
    
    if @props.notifications
      notifications = @props.notifications.map (notification, i) =>
        if notification.type is "error"
          message = (
            <p>
              <strong>There was an error:</strong> {notification.message}
            </p>
          )

        <div key={i} className='notice'>
          <div className='container'>
            {message}
          </div>
        </div>

    <div className="notifications">
      {notifications}
    </div>
)

# Exports
#----------------------------------------

module.exports = Notifications