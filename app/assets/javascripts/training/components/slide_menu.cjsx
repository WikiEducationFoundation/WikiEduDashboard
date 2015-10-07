React  = require 'react'

SlideMenu = React.createClass(
  render: ->
    # need the slide index because overflow: hidden cuts off li numbering
    slides = @props.slides.map (slide, index) =>
      liClass = if @props.currentSlideId == index + 1 then 'current' else ''
      <li className={liClass}>
        {index + 1}. {slide.title}
      </li>
    menuClass = "slide__menu__nav "
    menuClass += @props.menuClass

    <div className={menuClass}>
      <span className="dropdown__close" onClick={@props.onClick}>&times;</span>
      <ol>
        {slides}
      </ol>
    </div>

)

module.exports = SlideMenu
