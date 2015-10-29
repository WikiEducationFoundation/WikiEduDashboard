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
    if @props.direction is 'Previous'
      linkText = "< #{@props.direction} Page: #{@props.slideTitle}"
    else
      linkText = "Next Page"
    <Link disabled={@props.disabled} onClick={@props.onClick} className={linkClass} to="slide" params={linkParams}>
      {linkText}
    </Link>
)

module.exports = SlideLink
