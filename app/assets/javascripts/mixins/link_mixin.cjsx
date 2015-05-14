React     = require 'react/addons'
Router    = require 'react-router'
Link      = Router.Link

LinkMixin =
  contextTypes:
    router: React.PropTypes.func.isRequired
  routeParams: ->
    @context.router.getCurrentParams()
  link: (to, text, class_name=null) ->
    <Link to={to} params={@routeParams()} className={class_name}>{text}</Link>
  transitionTo: (to, params=null) ->
    this.context.router.transitionTo(to, params || @routeParams())

module.exports = LinkMixin
