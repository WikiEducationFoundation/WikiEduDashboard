React        = require 'react/addons'
Router       = require 'react-router'
RouteHandler = Router.RouteHandler

DidYouKnowHandler = React.createClass(
  displayName: 'DidYouKnowHandler'
  render: ->
    <div className='container'>
      <h1>Hello from did you know</h1>
    </div>
)

module.exports = DidYouKnowHandler
