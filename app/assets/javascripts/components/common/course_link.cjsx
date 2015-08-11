React     = require 'react/addons'
Router    = require 'react-router'
Link      = Router.Link

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
