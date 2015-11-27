React  = require 'react'
Router = require 'react-router'
Link   = Router.Link

SlideMenu = React.createClass(
  displayName: 'SlideMenu'
  linkParams: (props) ->
    library_id: props.params.library_id
    module_id: props.params.module_id
  componentWillMount: ->
    window.addEventListener 'click', @props.closeMenu, false
  componentWillUnmount: ->
    window.removeEventListener 'click', @props.closeMenu, false
  render: ->
    if @props.slides
      # need the slide index because overflow: hidden cuts off li numbering
      params = @linkParams(@props)
      slides = @props.slides.map (slide, loopIndex) =>
        current = slide.id == @props.currentSlide.id
        liClass = if current then 'current' else ''
        newParams = _.extend @linkParams(@props), slide_id: slide.slug
        link = "/training/#{newParams.library_id}/#{newParams.module_id}/#{newParams.slide_id}"
        # a slide is enabled if it comes back from the API as such,
        # it is set enabled in the parent component,
        # or it's the current slide
        enabled = (slide.enabled is true || @props.enabledSlides.indexOf(slide.id) >= 0) && !current
        <li key={[slide.id, loopIndex].join('-')} onClick={@props.onClick} className={liClass}>
          <a disabled={!enabled} href={!enabled && 'javascript:void(0)' || link}>
            {loopIndex + 1}. {slide.title}
          </a>
        </li>

    menuClass = "slide__menu__nav__dropdown "
    menuClass += @props.menuClass

    <div className={menuClass}>
      <span className="dropdown__close pull-right" onClick={@props.onClick}>&times;</span>
      <h1 className="h5 capitalize">Table of Contents</h1>
      <ol>
        {slides}
      </ol>
    </div>

)

module.exports = SlideMenu
