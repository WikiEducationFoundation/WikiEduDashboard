React = require 'react'
Router = require 'react-router'
# Course = require("./course/course.cjsx")
Timeline = require("./components/timeline.cjsx")

routes = (
  <Router.Route path='/'>
    <Router.Route name='timeline' path='/courses/:course_school/:course_title/timeline' handler={Timeline} />
    <Router.Redirect from='*' to='*' />
  </Router.Route>
)

if document.getElementById('timeline')
  react_root = document.getElementById('timeline')
  Router.run routes, Router.HistoryLocation, (Handler) ->
    React.render(<Handler/>, react_root)