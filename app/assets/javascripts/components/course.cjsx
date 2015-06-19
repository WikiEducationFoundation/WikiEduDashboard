React             = require 'react'
Router            = require 'react-router'
Link              = Router.Link
RouteHandler      = Router.RouteHandler
ServerActions     = require '../actions/server_actions'
CourseActions     = require '../actions/course_actions'
CourseStore       = require '../stores/course_store'
UserStore         = require '../stores/user_store'

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
    ServerActions.fetchCourse @getCourseID()
    ServerActions.fetchUsers @getCourseID()
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
    to_pass = $.extend(true, {}, @state.course)
    to_pass['submitted'] = true
    CourseActions.updateCourse to_pass, true
  routeParams: ->
    @context.router.getCurrentParams()
  render: ->
    route_params = @context.router.getCurrentParams()

    alerts = []
    if !(@state.course.submitted || @state.course.published || @state.listed) && !@state.course.legacy
      alerts.push (
        <div className='container module text-center' key='submit'>
          <p>Your course is not yet published on the Wiki Edu platform. <a href="#" onClick={@submit}>Click here</a> to submit it for approval by Wiki Edu staff.</p>
        </div>
      )
    else if @state.course.submitted && !@state.course.published && !@getCurrentUser().admin && !@state.course.legacy
      alerts.push (
        <div className='container module text-center' key='submit'>
          <p>Your course has been submitted for addition to a cohort. Wiki Edu staff will review and get in touch with any questions.</p>
        </div>
      )

    if @state.course.submitted && !@state.course.published && @getCurrentUser().admin && !@state.course.legacy
      alerts.push (
        <div className='container module text-center' key='publish'>
          <p>This course has been submitted for approval by its creator. <a href="#">Click here</a> to add it to a cohort!</p>
        </div>
      )

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
      {alerts}
      <div className="course_main container">
        <RouteHandler {...@props}
          course_id={@getCourseID()}
          current_user={@getCurrentUser()}
          transitionTo={@transitionTo}
        />
      </div>
    </div>
)

module.exports = Course
