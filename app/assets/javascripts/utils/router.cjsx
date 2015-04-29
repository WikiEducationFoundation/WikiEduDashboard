React = require 'react'
Router = require 'react-router'
# Course = require("./course/course.cjsx")
Timeline = require("../components/timeline/timeline.cjsx")
Overview = require("../components/overview/overview.cjsx")

routes = (
  <Router.Route path='/'>
    <Router.Route name='timeline' path='/courses/:course_school/:course_title/timeline' handler={Timeline} />
    <Router.Route name='overview' path='/courses/:course_school/:course_title/overview' handler={Overview} />
  </Router.Route>
)

if document.getElementById('react_root')
  react_root = document.getElementById('react_root')
  Router.run routes, Router.HistoryLocation, (Handler) ->
    React.render(<Handler/>, react_root)