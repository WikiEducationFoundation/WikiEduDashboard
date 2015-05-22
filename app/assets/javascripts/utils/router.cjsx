React               = require 'react'
Router              = require 'react-router'
Route               = Router.Route
DefaultRoute        = Router.DefaultRoute
App                 = require '../components/app'
Wizard              = require '../components/wizard/wizard'
TimelineHandler     = require '../components/timeline/timeline_handler'
OverviewHandler     = require '../components/overview/overview_handler'
CourseCreator       = require '../components/course_creator/course_creator'
CourseCreatorButton = require '../components/course_creator/course_creator_button'

routes = (
  <Route name='root' path='/' handler={App}>
    <Route name='course' path='courses'>
      <Route name='timeline' path=':course_school/:course_title/timeline' handler={TimelineHandler} >
        <Route name='wizard' path='wizard' handler={Wizard} />
      </Route>
      <Route name='overview' path=':course_school/:course_title/overview' handler={OverviewHandler} />
    </Route>
    <Route handler={CourseCreatorButton}>
      <Route name='course_creator' path='course_creator' handler={CourseCreator} />
    </Route>
    <DefaultRoute handler={CourseCreatorButton} />
  </Route>
)

Router.run routes, Router.HistoryLocation, (Handler) ->
  react_root = document.getElementById('react_root')
  React.render(<Handler/>, react_root) if $('#react_root').length