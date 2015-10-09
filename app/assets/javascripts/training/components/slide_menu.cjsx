React  = require 'react'
Router = require 'react-router'
Link   = Router.Link

SlideMenu = React.createClass(
  linkParams: (props) ->
    library_id: props.params.library_id
    module_id: props.params.module_id
  render: ->
    if @props.slides
      # need the slide index because overflow: hidden cuts off li numbering
      params = @linkParams(@props)
      slides = @props.slides.map (slide, index) =>
        liClass = if @props.currentSlide.id == index + 1 then 'current' else ''
        newParams = _.extend @linkParams(@props), slide_id: slide.slug
        <li key={slide.id} onClick={@props.onClick} className={liClass}>
          <Link to="slide" params={newParams}>
            {index + 1}. {slide.title}
          </Link>
        </li>

    menuClass = "slide__menu__nav__dropdown "
    menuClass += @props.menuClass

    <div className={menuClass}>
      <span className="dropdown__close" onClick={@props.onClick}>&times;</span>
      <ol>
        {slides}
      </ol>
    </div>

)

module.exports = SlideMenu
