React               = require 'react'
ReactDOM            = require 'react-dom'
render              = ReactDOM.render
ReactRouter         = require 'react-router'
Router              = ReactRouter.Router
Route               = ReactRouter.Route
IndexRoute          = ReactRouter.IndexRoute
Redirect            = ReactRouter.Redirect

App                 = require '../components/app.cjsx'
Course              = require '../components/course.cjsx'
Onboarding          = require '../components/onboarding/index.cjsx'
Wizard              = require '../components/wizard/wizard.cjsx'
Dates               = require '../components/timeline/meetings.cjsx'
CourseCreator       = require '../components/course_creator/course_creator.cjsx'

OverviewHandler     = require '../components/overview/overview_handler.cjsx'
TimelineHandler     = require '../components/timeline/timeline_handler.cjsx'
RevisionsHandler    = require '../components/revisions/revisions_handler.cjsx'
StudentsHandler     = require '../components/students/students_handler.cjsx'
ArticlesHandler     = require '../components/articles/articles_handler.cjsx'
UploadsHandler      = require '../components/uploads/uploads_handler.cjsx'

RecentActivityHandler = require '../components/activity/recent_activity_handler.cjsx'
DidYouKnowHandler     = require '../components/activity/did_you_know_handler.cjsx'
PlagiarismHandler     = require '../components/activity/plagiarism_handler.cjsx'
RecentEditsHandler     = require '../components/activity/recent_edits_handler.cjsx'

TrainingApp           = require '../training/components/training_app.cjsx'
TrainingModuleHandler = require '../training/components/training_module_handler.cjsx'
TrainingSlideHandler  = require '../training/components/training_slide_handler.cjsx'

browserHistory = ReactRouter.browserHistory

# Handle scroll position for back button, hashes, and normal links
browserHistory.listen (location) =>
  setTimeout () =>
    if location.action == 'POP'
      return
    hash = window.location.hash
    if hash
      element = document.querySelector(hash)
      if element
        element.scrollIntoView
          block: 'start'
          behavior: 'smooth'
    else
      window.scrollTo 0, 0

routes = (
  <Route path='/' component={App}>
    <Route path='onboarding' component={Onboarding.Root}>
      <IndexRoute component={Onboarding.Intro} />
      <Route path='form' component={Onboarding.Form} />
      <Route path='permissions' component={Onboarding.Permissions} />
      <Route path='finish' component={Onboarding.Finished} />
    </Route>
    <Route path='recent-activity' component={RecentActivityHandler}>
      <IndexRoute component={DidYouKnowHandler} />
      <Route path='plagiarism' component={PlagiarismHandler} />
      <Route path='recent-edits' component={RecentEditsHandler} />
    </Route>
    <Route path='courses'>
      <Route path=':course_school/:course_title' component={Course}>
        <IndexRoute component={OverviewHandler} />
        <Route path="overview" component={OverviewHandler} />
        <Route path='timeline' component={TimelineHandler}>
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

el = document.getElementById('react_root')
render((
  <Router history={browserHistory}>
    {routes}
  </Router>
), el) if el?
