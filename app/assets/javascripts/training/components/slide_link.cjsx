React  = require 'react'
Router = require 'react-router'
Link   = Router.Link

SlideLink = React.createClass(
  render: ->
    linkClass = 'slide-nav'
    buttonClasses = ' btn btn-primary icon icon-rt_arrow'
    linkClass += if @props.button then buttonClasses else ''
    if @props.direction is 'Previous'
      linkText = "< #{@props.direction} Page: #{@props.slideTitle}"
    else
      linkText = "Next Page"
    linkParams = _.merge(@props.linkParams, {slide_id: @props.slideId})

    <Link disabled={@props.disabled} onClick={@props.onClick} className={linkClass} to="slide" params={linkParams}>
      {linkText}
    </Link>
)

module.exports = SlideLink
