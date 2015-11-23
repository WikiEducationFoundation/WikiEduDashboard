React       = require 'react'
ReactRouter = require 'react-router'
Router      = ReactRouter.Router
Link        = ReactRouter.Link

CourseLink = React.createClass(
  displayname: 'CourseLink'
  render: ->
    <Link
      to={@props.to}
      onClick={@props.onClick}
      className={@props.className}>
        {@props.children}
    </Link>
)

module.exports = CourseLink
