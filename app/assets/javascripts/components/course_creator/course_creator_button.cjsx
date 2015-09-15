React           = require 'react'
Router          = require 'react-router'
Link            = Router.Link
RouteHandler    = Router.RouteHandler
TransitionGroup = require '../../utils/TransitionGroup'

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
      <TransitionGroup
        transitionName="wizard"
        component='div'
        enterTimeout={500}
        leaveTimeout={500}
      >
        <RouteHandler key={Date.now()} />
      </TransitionGroup>
    </div>
)

module.exports = CourseCreatorButton
