React             = require 'react'
Router            = require 'react-router'
Link              = Router.Link
CourseLink        = require './common/course_link'
ServerActions     = require '../actions/server_actions'
CourseActions     = require '../actions/course_actions'
CourseStore       = require '../stores/course_store'
UserStore         = require '../stores/user_store'
CohortStore       = require '../stores/cohort_store'

getState = ->
  current = $('#react_root').data('current_user')
  cu = UserStore.getFiltered({ id: current.id })[0]
  return {
    course: CourseStore.getCourse()
    current_user: cu || current
  }

Course = React.createClass(
  displayName: 'Course'
  mixins: [CourseStore.mixin, UserStore.mixin]
  contextTypes:
    router: React.PropTypes.func.isRequired
  componentWillMount: ->
    ServerActions.fetch 'course', @getCourseID()
    ServerActions.fetch 'users', @getCourseID()
    ServerActions.fetch 'cohorts', @getCourseID()
  getInitialState: ->
    getState()
  storeDidChange: ->
    @setState getState()
  transitionTo: (to, params=null) ->
    @context.router.transitionTo(to, params || @routeParams())
  getCourseID: ->
    params = @context.router.getCurrentParams()
    return params.course_school + '/' + params.course_title
  getCurrentUser: ->
    @state.current_user
  submit: (e) ->
    e.preventDefault()
    return unless confirm "Upon submission, this course will be automatically posted to Wikipedia with your user account. After that, new edits to the timeline will be mirrored to Wikipedia.\n\nAre you sure you want to do this?"
    to_pass = $.extend(true, {}, @state.course)
    to_pass['submitted'] = true
    CourseActions.updateCourse to_pass, true
  routeParams: ->
    @context.router.getCurrentParams()
  render: ->
    route_params = @context.router.getCurrentParams()

    alerts = []

    if @getCurrentUser().id?
      user_obj = UserStore.getFiltered({ id: @getCurrentUser().id })[0]
    user_role = if user_obj? then user_obj.role else -1

    if (user_role > 0 || @getCurrentUser().admin) && !@state.course.legacy && !@state.course.published
      if CourseStore.isLoaded() && !(@state.course.submitted || @state.published)
        alerts.push (
          <div className='notification' key='submit'>
            <div className='container'>
              <p>Please review this timeline and make changes. Once you're satisfied with your timeline, submit it for approval by Wiki Ed staff. Once approved, you will be given an enrollment URL that students can use to join the course.</p>
              <a href="#" onClick={@submit} className='button'>Submit</a>
            </div>
          </div>
        )
      if @state.course.submitted
        if !@getCurrentUser().admin
          alerts.push (
            <div className='notification' key='submit'>
              <div className='container'>
                <p>Your course has been submitted. Wiki Ed staff will review it and get in touch with any questions.</p>
              </div>
            </div>
          )
        else
          alerts.push (
            <div className='notification' key='publish'>
              <div className='container'>
                <p>This course has been submitted for approval by its creator. To approve it, add it to a cohort on the Overview page.</p>
                <CourseLink to='overview' className="button">Overview</CourseLink>
              </div>
            </div>
          )

      if @state.course.next_upcoming_assigned_module
        # `table` key is because it comes back as an openstruct
        module = @state.course.next_upcoming_assigned_module.table
        alerts.push(
          <div className='notification' key='upcoming_module'>
            <div className='container'>
              <p>The training module "{module.title}" is assigned for this course, and is due on {module.due_date}.</p>
              <a href={module.link} className="button pull-right">Go to training</a>
            </div>
          </div>
        )

      if @state.course.first_overdue_module
        # `table` key is because it comes back as an openstruct
        module = @state.course.first_overdue_module.table
        alerts.push(
          <div className='notification' key='upcoming_module'>
            <div className='container'>
              <p>The training module "{module.title}" is assigned for this course, and was due on {module.due_date}.</p>
              <a href={module.link} className="button pull-right">Go to training</a>
            </div>
          </div>
        )

    if (user_role > 0 || @getCurrentUser().admin) && @state.course.published && UserStore.isLoaded() && UserStore.getFiltered({ role: 0 }).length == 0 && !@state.course.legacy
      alerts.push (
        <div className='notification' key='enroll'>
          <div className='container'>
            <p>Your course has been published! Students may enroll in the course by visiting the following URL:</p>
            <p>{@state.course.enroll_url + @state.course.passcode}</p>
          </div>
        </div>
      )

    #################################################

    unless @state.course.legacy
      timeline = (
        <div className="nav__item" id="timeline-link">
          <p><Link params={route_params} to="timeline">Timeline</Link></p>
        </div>
      )

    <div>
      <header className='course-page'>
        <div className="container">
          <div className="title">
            <a href={@state.course.url} target="_blank">
              <h2>{@state.course.title}</h2>
            </a>
          </div>
          <div className="stat-display">
            <div className="stat-display__stat" id="articles-created">
              <h3>{@state.course.created_count}</h3>
              <small>Articles Created</small>
            </div>
            <div className="stat-display__stat" id="articles-edited">
              <h3>{@state.course.edited_count}</h3>
              <small>Articles Edited</small>
            </div>
            <div className="stat-display__stat" id="total-edits">
              <h3>{@state.course.edit_count}</h3>
              <small>Total Edits</small>
            </div>
            <div className="stat-display__stat popover-trigger" id="student-editors">
              <h3>{@state.course.student_count}</h3>
              <small>Student Editors</small>
              <div className="popover dark" id="trained-count">
                <h4>{@state.course.trained_count}</h4>
                <p>have completed training</p>
              </div>
            </div>
            <div className="stat-display__stat" id="characters-added">
              <h3>{@state.course.character_count}</h3>
              <small>Chars Added</small>
            </div>
            <div className="stat-display__stat" id="view-count">
              <h3>{@state.course.view_count}</h3>
              <small>Article Views</small>
            </div>
          </div>
        </div>
      </header>
      {alerts}

      <div className="course_navigation">
        <nav className='container'>
          <div className="nav__item" id="overview-link">
            <p><Link params={route_params} to="overview">Overview</Link></p>
          </div>
          {timeline}
          <div className="nav__item" id="students-link">
            <p><Link params={route_params} to="students">Students</Link></p>
          </div>
          <div className="nav__item" id="articles-link">
            <p><Link params={route_params} to="articles">Articles</Link></p>
          </div>
          <div className="nav__item" id="uploads-link">
            <p><Link params={route_params} to="uploads">Uploads</Link></p>
          </div>
          <div className="nav__item" id="activity-link">
            <p><Link params={route_params} to="activity">Activity</Link></p>
          </div>
        </nav>
      </div>
      <div className="course_main container">
        {React.cloneElement(@props.children, course_id: @getCourseID(), current_user: @getCurrentUser(), transitionTo: @transitionTo, course:  @state.course)}
      </div>
    </div>
)

module.exports = Course
