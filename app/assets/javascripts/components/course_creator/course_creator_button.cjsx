React           = require 'react'
ReactRouter     = require 'react-router'
Router          = ReactRouter.Router
Link            = ReactRouter.Link

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
