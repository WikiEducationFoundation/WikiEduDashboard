React  = require 'react'
Router = require 'react-router'
Link   = Router.Link

SlideLink = React.createClass(
  displayName: 'SlideLink'
  linkParams: (props) ->
    library_id: props.params.library_id
    module_id: props.params.module_id
    slide_id: props.slideId
  render: ->
    linkParams = @linkParams(@props)
    linkClass = 'slide-nav'
    buttonClasses = ' btn btn-primary icon icon-rt_arrow'
    linkClass += if @props.button then buttonClasses else ''
    <Link disabled={@props.disabled} onClick={@props.onClick} className={linkClass} to="slide" params={linkParams}>
      {@props.direction} Page
    </Link>
)

module.exports = SlideLink
