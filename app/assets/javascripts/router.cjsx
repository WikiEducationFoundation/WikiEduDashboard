React = require 'react'
Router = require 'react-router'
# Course = require("./course/course.cjsx")
Timeline = require("./components/timeline.cjsx")

routes = (
  <Router.Route name='timeline' path='/courses/:course_school/:course_title/timeline' handler={Timeline} />
)

Router.run routes, Router.HistoryLocation, (Handler) ->
  React.render(<Handler/>, document.getElementById('timeline'))