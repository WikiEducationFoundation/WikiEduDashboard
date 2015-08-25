React        = require 'react/addons'
Router       = require 'react-router'
RouteHandler = Router.RouteHandler

PlagiarismHandler = React.createClass(
  displayName: 'PlagiarismHandler'
  render: ->
    <div className='container'>
      <h1>Hello from plagiarism</h1>
    </div>
)

module.exports = PlagiarismHandler
