React     = require 'react/addons'
Router    = require 'react-router'
Link      = Router.Link

StudentLink = React.createClass(
  displayname: 'StudentLink'
  render: ->
    <a
      href={@props.to}
      params={@routeParams()}
      className={@props.className}>
        {@props.children}
    </a>
)

module.exports = StudentLink
