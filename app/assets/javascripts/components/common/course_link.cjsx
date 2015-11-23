React       = require 'react'
ReactRouter = require 'react-router'
Router      = ReactRouter.Router
Link        = ReactRouter.Link

CourseLink = React.createClass(
  displayname: 'CourseLink'
  contextTypes:
    router: React.PropTypes.func.isRequired
  routeParams: ->
    @context.router.getCurrentParams()
  render: ->
    <Link
      to={@props.to}
      onClick={@props.onClick}
      params={@routeParams()}
      className={@props.className}>
        {@props.children}
    </Link>
)

module.exports = CourseLink
