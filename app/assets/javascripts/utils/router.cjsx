React = require 'react'
Router = require 'react-router'
# Course = require("./course/course.cjsx")
TimelineHandler = require("../components/timeline/timeline_handler.cjsx")
OverviewHandler = require("../components/overview/overview_handler.cjsx")

routes = (
  <Router.Route path='/'>
    <Router.Route name='timeline' path='/courses/:course_school/:course_title/timeline' handler={TimelineHandler} />
    <Router.Route name='overview' path='/courses/:course_school/:course_title/overview' handler={OverviewHandler} />
  </Router.Route>
)

if document.getElementById('react_root')
  react_root = document.getElementById('react_root')
  Router.run routes, Router.HistoryLocation, (Handler) ->
    React.render(<Handler/>, react_root)