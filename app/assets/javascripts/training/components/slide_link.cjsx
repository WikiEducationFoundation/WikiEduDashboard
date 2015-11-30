React  = require 'react'
Router = require 'react-router'
Link   = Router.Link

SlideLink = React.createClass(
  displayName: 'SlideLink'
  linkParams: (props) ->
    library_id: props.params.library_id
    module_id: props.params.module_id
    slide_id: props.slideId
  _slideLink: (props) ->
    "/training/#{props.library_id}/#{props.module_id}/#{props.slide_id}"
  render: ->
    linkParams = @linkParams(@props)
    linkClass = 'slide-nav'
    buttonClasses = ' btn btn-primary icon icon-rt_arrow'
    linkClass += if @props.button then buttonClasses else ''
    href = @_slideLink(linkParams)
    <Link data-href={href} disabled={@props.disabled} className={linkClass} to={href}>
      {@props.direction} Page
    </Link>
)

module.exports = SlideLink
