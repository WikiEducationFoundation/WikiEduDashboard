React        = require 'react/addons'
Router       = require 'react-router'
RouteHandler = Router.RouteHandler

MainspaceHandler = React.createClass(
  displayName: 'MainspaceHandler'
  render: ->
    <div className='container'>
      <h1>Hello from mainspace</h1>
    </div>
)

module.exports = MainspaceHandler
