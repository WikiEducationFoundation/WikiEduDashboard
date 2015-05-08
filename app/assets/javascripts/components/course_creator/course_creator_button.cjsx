React         = require 'react/addons'
Router        = require 'react-router'
Link          = Router.Link
RouteHandler  = Router.RouteHandler
RCSSTGroup    = React.addons.CSSTransitionGroup

CourseCreatorButton = React.createClass(
  displayName: 'CourseCreatorButton'
  render: ->
    <div>
      <Link
        to="course_creator"
        className="button large dark"
      >Create New Course</Link>
      <RouteHandler />
    </div>
)

module.exports = CourseCreatorButton