React               = require 'react'
Router              = require 'react-router'
Route               = Router.Route
DefaultRoute        = Router.DefaultRoute
Redirect            = Router.Redirect

App                 = require '../components/app'
Course              = require '../components/course'
Wizard              = require '../components/wizard/wizard'
Dates               = require '../components/timeline/meetings'
CourseCreator       = require '../components/course_creator/course_creator'
CourseCreatorButton = require '../components/course_creator/course_creator_button'

OverviewHandler     = require '../components/overview/overview_handler'
TimelineHandler     = require '../components/timeline/timeline_handler'
RevisionsHandler    = require '../components/revisions/revisions_handler'
StudentsHandler     = require '../components/students/students_handler'
ArticlesHandler     = require '../components/articles/articles_handler'
UploadsHandler      = require '../components/uploads/uploads_handler'

RecentActivityHandler = require '../components/activity/recent_activity_handler'
DidYouKnowHandler     = require '../components/activity/did_you_know_handler'
MainspaceHandler      = require '../components/activity/mainspace_handler'
PlagiarismHandler     = require '../components/activity/plagiarism_handler'
RecentEditsHandler     = require '../components/activity/recent_edits_handler'

TrainingApp           = require '../training/components/training_app'
TrainingModuleHandler = require '../training/components/training_module_handler'
TrainingSlideHandler  = require '../training/components/training_slide_handler'

routes = (
  <Route name='root' path='/' handler={App}>
    <DefaultRoute handler={CourseCreatorButton} />
    <Route path='recent-activity' name='recent-activity' handler={RecentActivityHandler}>
      <DefaultRoute name='did-you-know' handler={DidYouKnowHandler} />
      <Route path='mainspace' name='mainspace' handler={MainspaceHandler} />
      <Route path='plagiarism' name='plagiarism' handler={PlagiarismHandler} />
      <Route path='recent-edits' name='recent-edits' handler={RecentEditsHandler} />
    </Route>
    <Route path='courses'>
      <DefaultRoute handler={CourseCreatorButton} />
      <Route name='course' path=':course_school/:course_title' handler={Course}>
        <DefaultRoute name='overview' handler={OverviewHandler} />
        <Route name='timeline' path='timeline' handler={TimelineHandler} >
          <Route name='wizard' path='wizard' handler={Wizard} />
          <Route name='dates' path='dates' handler={Dates} />
        </Route>
        <Route name='activity' path='activity' handler={RevisionsHandler}></Route>
        <Route name='students' path='students' handler={StudentsHandler}></Route>
        <Route name='articles' path='articles' handler={ArticlesHandler}></Route>
        <Route name='uploads' path='uploads' handler={UploadsHandler}></Route>
      </Route>
    </Route>
    <Route name='course_creator' path='course_creator' handler={CourseCreator} />
    <Route path='training' handler={TrainingApp} >
      <Route name='module' path=':library_id/:module_id' handler={TrainingModuleHandler} />
      <Route name='slide' path='/training/:library_id/:module_id/:slide_id' handler={TrainingSlideHandler} />
    </Route>
  </Route>
)

Router.run routes, Router.HistoryLocation, (Handler) ->
  react_root = document.getElementById('react_root')
  React.render(<Handler/>, react_root) if $('#react_root').length
