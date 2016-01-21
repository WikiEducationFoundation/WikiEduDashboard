React             = require 'react'
ReactRouter       = require 'react-router'
Link              = ReactRouter.Link
CourseLink        = require './common/course_link'
ServerActions     = require '../actions/server_actions'
CourseActions     = require '../actions/course_actions'
CourseStore       = require '../stores/course_store'
UserStore         = require '../stores/user_store'
CohortStore       = require '../stores/cohort_store'
Affix             = require './common/affix'

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
  componentWillMount: ->
    ServerActions.fetch 'course', @getCourseID()
    ServerActions.fetch 'users', @getCourseID()
    ServerActions.fetch 'cohorts', @getCourseID()
  getInitialState: ->
    getState()
  storeDidChange: ->
    @setState getState()
  getCourseID: ->
    params = @props.params
    return params.course_school + '/' + params.course_title
  getCurrentUser: ->
    @state.current_user
  submit: (e) ->
    e.preventDefault()
    return unless confirm "Upon submission, this course will be automatically posted to Wikipedia with your user account. After that, new edits to the timeline will be mirrored to Wikipedia.\n\nAre you sure you want to do this?"
    to_pass = $.extend(true, {}, @state.course)
    to_pass['submitted'] = true
    CourseActions.updateCourse to_pass, true
  _courseLinkParams: ->
    "/courses/#{@props.params.course_school}/#{@props.params.course_title}"
  _onCourseIndex: ->
    @props.location.pathname.split('/').length is 3
  render: ->
    alerts = []
    route_params = @props.params

    courseLink =
      if @state.course.url?
        (<a href={@state.course.url} target="_blank">
          <h2 className="title">{@state.course.title}</h2>
        </a>)
      else
        (<a><h2 className="title">{@state.course.title}</h2></a>)

    # Set interface strings based on course type
    if @state.course.type == 'ClassroomProgramCourse'
      usersTabLabel = I18n.t('courses.students_short')
    else
      usersTabLabel = I18n.t('courses.editors')

    if @getCurrentUser().id?
      user_obj = UserStore.getFiltered({ id: @getCurrentUser().id })[0]
    user_role = if user_obj? then user_obj.role else -1

    if (user_role > 0 || @getCurrentUser().admin) && !@state.course.legacy && !@state.course.published
      if CourseStore.isLoaded() && !(@state.course.submitted || @state.published)
        alerts.push (
          <div className='notification' key='submit'>
            <div className='container'>
              <p>Please review this timeline and make changes. Once you're satisfied with your timeline, submit it for approval by Wiki Ed staff. Once approved, you will be given an enrollment URL that students can use to join the course. (You'll still be able to make edits later.)</p>
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
                <CourseLink to="#{@_courseLinkParams()}/overview" className="button">Overview</CourseLink>
              </div>
            </div>
          )

      if @state.course.next_upcoming_assigned_module && user_role > 0
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

      if @state.course.first_overdue_module && user_role > 0
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
      url = window.location.href.replace(window.location.pathname, "") + @_courseLinkParams() + "?enroll=" + @state.course.passcode
      alerts.push (
        <div className='notification' key='enroll'>
          <div className='container'>
            <div>
              <p>Your course has been published! Students may enroll in the course by visiting the following URL:</p>
              <a href={url}>{url}</a>
            </div>
          </div>
        </div>
      )

    unless @state.course.legacy
      timeline = (
        <div className="nav__item" id="timeline-link">
          <p><Link to={"#{@_courseLinkParams()}/timeline"} activeClassName='active'>Timeline</Link></p>
        </div>
      )

    overviewLinkClassName = 'active' if @_onCourseIndex()

    if @props.location.query.enroll
      if @getCurrentUser().id?
        if user_role == -1
          enroll_card = (
            <div className="module enroll">
              <a href={@_courseLinkParams()}>
                <svg className="close" tabIndex="0" viewBox="0 0 24 24" preserveAspectRatio="xMidYMid meet" style={{"fill":"currentcolor", "verticalAlign": "middle", "width":"32px", "height":"32px"}}><g><path d="M19 6.41l-1.41-1.41-5.59 5.59-5.59-5.59-1.41 1.41 5.59 5.59-5.59 5.59 1.41 1.41 5.59-5.59 5.59 5.59 1.41-1.41-5.59-5.59z"></path></g></svg>
              </a>
              <h1>Join '{@state.course.title}'?</h1>
              <a className="button dark" href={@state.course.enroll_url + @props.location.query.enroll}>Join</a>
              <a className="button border" href={@_courseLinkParams()}>Cancel</a>
            </div>
          )
        else
          enroll_card = (
            <div className="module enroll">
              <a href={@_courseLinkParams()}>
                <svg className="close" tabIndex="0" viewBox="0 0 24 24" preserveAspectRatio="xMidYMid meet" style={{"fill":"currentcolor", "verticalAlign": "middle", "width":"32px", "height":"32px"}}><g><path d="M19 6.41l-1.41-1.41-5.59 5.59-5.59-5.59-1.41 1.41 5.59 5.59-5.59 5.59 1.41 1.41 5.59-5.59 5.59 5.59 1.41-1.41-5.59-5.59z"></path></g></svg>
              </a>
              <h1>You are already part '{@state.course.title}'!</h1>
            </div>
          )
      else
        enroll_card = (
          <div className="module enroll">
            <a href={@_courseLinkParams()}>
              <svg className="close" tabIndex="0" viewBox="0 0 24 24" preserveAspectRatio="xMidYMid meet" style={{"fill":"currentcolor", "verticalAlign": "middle", "width":"32px", "height":"32px"}}><g><path d="M19 6.41l-1.41-1.41-5.59 5.59-5.59-5.59-1.41 1.41 5.59 5.59-5.59 5.59 1.41 1.41 5.59-5.59 5.59 5.59 1.41-1.41-5.59-5.59z"></path></g></svg>
            </a>
            <h1>Hello,</h1>
            <p>
              You’ve been invited to join {@state.course.title}. To join the course, you need to log in with a Wikipedia account.
              <br/> If you don’t have a Wikipedia account yet, sign up for one now.
            </p>
            <p>
              <a href={"/users/auth/mediawiki?origin=" + window.location} className="button auth dark"><i className="icon icon-wiki-logo"></i> Log in with Wikipedia</a>
              <a href={"/users/auth/mediawiki_signup?origin=" + window.loaction} className="button auth signup border"><i className="icon icon-wiki-logo"></i> Sign up with Wikipedia</a>
            </p>
          </div>
        )
    else if @props.location.query.enrolled
      enroll_card = (
        <div className="module enroll">
          <a href={@_courseLinkParams()}>
            <svg className="close" tabIndex="0" viewBox="0 0 24 24" preserveAspectRatio="xMidYMid meet" style={{"fill":"currentcolor", "verticalAlign": "middle", "width":"32px", "height":"32px"}}><g><path d="M19 6.41l-1.41-1.41-5.59 5.59-5.59-5.59-1.41 1.41 5.59 5.59-5.59 5.59 1.41 1.41 5.59-5.59 5.59 5.59 1.41-1.41-5.59-5.59z"></path></g></svg>
          </a>
          <h1>Welcome!</h1>
          <p>You’ve successfully joined {@state.course.title}.</p>
        </div>
      )

    <div>
      <Affix className="course-nav__wrapper" offset=55>
        <div className="course_navigation">
          <div className="container">
            {courseLink}
            <nav>
              <div className="nav__item" id="overview-link">
                <p><Link to="#{@_courseLinkParams()}/overview" className={overviewLinkClassName} activeClassName="active">Overview</Link></p>
              </div>
              {timeline}
              <div className="nav__item" id="students-link">
                <p><Link to="#{@_courseLinkParams()}/students" activeClassName="active">{usersTabLabel}</Link></p>
              </div>
              <div className="nav__item" id="articles-link">
                <p><Link to="#{@_courseLinkParams()}/articles" activeClassName="active">Articles</Link></p>
              </div>
              <div className="nav__item" id="uploads-link">
                <p><Link to="#{@_courseLinkParams()}/uploads" activeClassName="active">Uploads</Link></p>
              </div>
              <div className="nav__item" id="activity-link">
                <p><Link to="#{@_courseLinkParams()}/activity" activeClassName="active">Activity</Link></p>
              </div>
            </nav>
          </div>
        </div>
      </Affix>
      <div className='course-alerts'>
        {alerts}
      </div>
      <div className="course_main container">
        {enroll_card}
        {React.cloneElement(@props.children, course_id: @getCourseID(), current_user: @getCurrentUser(), course:  @state.course)}
      </div>
    </div>
)

module.exports = Course
