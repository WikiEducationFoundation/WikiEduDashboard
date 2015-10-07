React  = require 'react'
Router = require 'react-router'
Link   = Router.Link

SlideLink = React.createClass(
  linkParams: (props) ->
    library_id: props.params.library_id
    module_id: props.params.module_id
    slide_id: props.slideId 
  render: ->
    linkParams = @linkParams(@props)
    <Link className="btn btn-primary slide-nav" to="slide" params={linkParams}>
      {@props.direction} Slide: {@props.slideTitle}
    </Link>
)

module.exports = SlideLink
