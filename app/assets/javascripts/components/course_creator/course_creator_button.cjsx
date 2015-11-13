React           = require 'react'
Router          = require 'react-router'
Link            = Router.Link
RouteHandler    = Router.RouteHandler

CourseCreatorButton = React.createClass(
  displayName: 'CourseCreatorButton'
  render: ->
    style =
      marginLeft: 0
    <div>
      <Link
        to="course_creator"
        className="button dark"
        style={style}
      >Create a Course</Link>
    </div>
)

module.exports = CourseCreatorButton
