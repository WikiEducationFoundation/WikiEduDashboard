React               = require 'react'
ReactDOM            = require 'react-dom'
ReactRouter         = require 'react-router'
Router              = ReactRouter.Router
Route               = ReactRouter.Route
DefaultRoute        = ReactRouter.DefaultRoute
Redirect            = ReactRouter.Redirect

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
PlagiarismHandler     = require '../components/activity/plagiarism_handler'
RecentEditsHandler     = require '../components/activity/recent_edits_handler'

TrainingApp           = require '../training/components/training_app'
TrainingModuleHandler = require '../training/components/training_module_handler'
TrainingSlideHandler  = require '../training/components/training_slide_handler'

routes = (
  <Route path='/' component={App}>
    <Route path='/' component={CourseCreatorButton} />
    <Route path='recent-activity' component={RecentActivityHandler}>
      <Route path='did-you-know' component={DidYouKnowHandler} />
      <Route path='plagiarism' component={PlagiarismHandler} />
      <Route path='recent-edits' component={RecentEditsHandler} />
    </Route>
    <Route path='courses'>
      <Route path='/' component={CourseCreatorButton} />
      <Route path=':course_school/:course_title' component={Course}>
        <Route component={OverviewHandler} />
        <Route path='timeline' component={TimelineHandler} >
          <Route path='wizard' component={Wizard} />
          <Route path='dates' component={Dates} />
        </Route>
        <Route path='activity' component={RevisionsHandler}></Route>
        <Route path='students' component={StudentsHandler}></Route>
        <Route path='articles' component={ArticlesHandler}></Route>
        <Route path='uploads' component={UploadsHandler}></Route>
      </Route>
    </Route>
    <Route path='course_creator' component={CourseCreator} />
    <Route path='training' component={TrainingApp} >
      <Route path=':library_id/:module_id' component={TrainingModuleHandler} />
      <Route path='/training/:library_id/:module_id/:slide_id' component={TrainingSlideHandler} />
    </Route>
  </Route>
)

react_root = document.getElementById('react_root')
ReactDOM.render(<Router>{routes}</Router>, react_root)
