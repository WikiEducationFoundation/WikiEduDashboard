React               = require 'react'
Router              = require 'react-router'
Route               = Router.Route
DefaultRoute        = Router.DefaultRoute
TimelineHandler     = require("../components/timeline/timeline_handler.cjsx")
OverviewHandler     = require("../components/overview/overview_handler.cjsx")
CourseCreator       = require("../components/course_creator/course_creator.cjsx")
CourseCreatorButton = require("../components/course_creator/course_creator_button.cjsx")

routes = (
  <Route name='root' path='/'>
    <Route name='course_creator' path='course_creator' handler={CourseCreator} />
    <Route name='course' path='courses'>
      <Route name='timeline' path=':course_school/:course_title/timeline' handler={TimelineHandler} />
      <Route name='overview' path=':course_school/:course_title/overview' handler={OverviewHandler} />
    </Route>
    <DefaultRoute handler={CourseCreatorButton} />
  </Route>
)

Router.run routes, Router.HistoryLocation, (Handler) ->
  react_root = document.getElementById('react_root')
  React.render(<Handler/>, react_root) if $('#react_root').length