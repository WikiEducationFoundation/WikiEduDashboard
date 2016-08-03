React             = require 'react'
ReactRouter       = require 'react-router'
Link              = ReactRouter.Link
CourseLink        = require('./common/course_link.jsx').default
ServerActions     = require('../actions/server_actions.js').default
CourseActions     = require('../actions/course_actions.js').default
CourseStore       = require '../stores/course_store.coffee'
UserStore         = require '../stores/user_store.coffee'
CohortStore       = require '../stores/cohort_store.coffee'
NotificationStore = require '../stores/notification_store.coffee'
Affix             = require('./common/affix.jsx').default
CourseUtils       = require('../utils/course_utils.js').default
GetHelpButton     = require('../components/common/get_help_button.jsx').default

getState = ->
  current = $('#react_root').data('current_user')
  cu = UserStore.getFiltered({ id: current.id })[0]
  return {
    course: CourseStore.getCourse()
    current_user: cu || current
  }

Course = React.createClass(
  displayName: 'Course'
  mixins: [CourseStore.mixin, UserStore.mixin, NotificationStore.mixin]
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
    return unless confirm I18n.t("courses.warn_mirrored")
    to_pass = $.extend(true, {}, @state.course)
    to_pass['submitted'] = true
    CourseActions.updateCourse to_pass, true
  _courseLinkParams: ->
    "/courses/#{@props.params.course_school}/#{@props.params.course_title}"
  _onCourseIndex: ->
    @props.location.pathname.split('/').length is 3
  dismissSurvey: (surveyNotificationId) ->
    if confirm I18n.t('courses.dismiss_survey_confirm')
      CourseActions.dismissNotification(surveyNotificationId)
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

    if @getCurrentUser().id?
      user_obj = UserStore.getFiltered({ id: @getCurrentUser().id })[0]
    user_role = if user_obj? then user_obj.role else -1

    #################
    # Timeline link #
    #################
    if @state.course.type == 'ClassroomProgramCourse'
      timeline = (
        <div className="nav__item" id="timeline-link">
          <p><Link to={"#{@_courseLinkParams()}/timeline"} activeClassName='active'>{I18n.t("courses.timeline_link")}</Link></p>
        </div>
      )

    ###################
    # Get Help button #
    ###################
    if Features.enableGetHelpButton
      getHelp = (
        <div className="nav__button" id="get-help-button">
          <GetHelpButton course={@state.course} current_user={@getCurrentUser()} key='get_help'/>
        </div>
      )

    ####################################
    # Admin / Instructor notifications #
    ####################################
    if (user_role > 0 || @getCurrentUser().admin) && !@state.course.legacy && !@state.course.published
      if CourseStore.isLoaded() && !(@state.course.submitted || @state.published) && @state.course.type == 'ClassroomProgramCourse'
        alerts.push (
          <div className='notification' key='submit'>
            <div className='container'>
              <p>{I18n.t("courses.review_timeline")}</p>
              <a href="#" onClick={@submit} className='button'>{I18n.t("application.submit")}</a>
            </div>
          </div>
        )

      if @state.course.submitted
        if !@getCurrentUser().admin
          alerts.push (
            <div className='notification' key='submit'>
              <div className='container'>
                <p>{I18n.t("courses.submitted_note")}</p>
              </div>
            </div>
          )
        else
          alerts.push (
            <div className='notification' key='publish'>
              <div className='container'>
                <p>{I18n.t("courses.submitted_admin")}</p>
                <CourseLink to="#{@_courseLinkParams()}/overview" className="button">{I18n.t("courses.overview")}</CourseLink>
              </div>
            </div>
          )

    if (user_role > 0 || @getCurrentUser().admin) && @state.course.published && UserStore.isLoaded() && UserStore.getFiltered({ role: 0 }).length == 0 && !@state.course.legacy
      url = window.location.origin + @_courseLinkParams() + "?enroll=" + @state.course.passcode
      alerts.push (
        <div className='notification' key='enroll'>
          <div className='container'>
            <div>
              <p>{CourseUtils.i18n('published', @state.course.string_prefix)}</p>
              <a href={url}>{url}</a>
            </div>
          </div>
        </div>
      )

    ##########################
    # Training notifications #
    ##########################
    if @state.course.incomplete_assigned_modules && @state.course.incomplete_assigned_modules.length
      # `table` key is because it comes back as an openstruct
      module = @state.course.incomplete_assigned_modules[0].table
      message_key = if moment().isAfter(module.due_date, 'day')
                      'courses.training_overdue'
                    else
                      'courses.training_due'

      alerts.push(
        <div className='notification' key='upcoming_module'>
          <div className='container'>
            <p>{I18n.t(message_key, title: module.title, date: module.due_date)}</p>
            <a href={module.link} className="button pull-right">{I18n.t("courses.training_nav")}</a>
          </div>
        </div>
      )

    ########################
    # Survey notifications #
    ########################
    if @state.course.survey_notifications? && @state.course.survey_notifications.length
      @state.course.survey_notifications.map (notification) =>
        alerts.push(
          <div className='notification notification--survey' key='upcoming_module' key={"survey_notification_#{notification.id}"}>
            <div className='container'>
              <p>{CourseUtils.i18n('survey.notification_message',@state.course.string_prefix)}</p>
              <a href={notification.survey_url} className="button pull-right">{CourseUtils.i18n('survey.link',@state.course.string_prefix)}</a>
              <button className='button small pull-right border inverse-border' onClick={=> @dismissSurvey(notification.id)}>{I18n.t("courses.dismiss_survey")}</button>
            </div>
          </div>
        )

    ####################
    # Enrollment modal #
    ####################
    if @props.location.query.enroll
      if @getCurrentUser().id?
        if user_role == -1
          enroll_card = (
            <div className="module enroll">
              <a href={@_courseLinkParams()}>
                <svg className="close" tabIndex="0" viewBox="0 0 24 24" preserveAspectRatio="xMidYMid meet" style={{"fill":"currentcolor", "verticalAlign": "middle", "width":"32px", "height":"32px"}}><g><path d="M19 6.41l-1.41-1.41-5.59 5.59-5.59-5.59-1.41 1.41 5.59 5.59-5.59 5.59 1.41 1.41 5.59-5.59 5.59 5.59 1.41-1.41-5.59-5.59z"></path></g></svg>
              </a>
              <h1>{I18n.t("courses.join_prompt", title: @state.course.title) if @state.course.title?}</h1>
              <a className="button dark" href={@state.course.enroll_url + @props.location.query.enroll}>{I18n.t("courses.join")}</a>
              <a className="button border" href={@_courseLinkParams()}>{I18n.t("application.cancel")}</a>
            </div>
          )
        else
          enroll_card = (
            <div className="module enroll">
              <a href={@_courseLinkParams()}>
                <svg className="close" tabIndex="0" viewBox="0 0 24 24" preserveAspectRatio="xMidYMid meet" style={{"fill":"currentcolor", "verticalAlign": "middle", "width":"32px", "height":"32px"}}><g><path d="M19 6.41l-1.41-1.41-5.59 5.59-5.59-5.59-1.41 1.41 5.59 5.59-5.59 5.59 1.41 1.41 5.59-5.59 5.59 5.59 1.41-1.41-5.59-5.59z"></path></g></svg>
              </a>
              <h1>{I18n.t("courses.already_enrolled", title: @state.course.title)}</h1>
            </div>
          )
      else
        enroll_card = (
          <div className="module enroll">
            <a href={@_courseLinkParams()}>
              <svg className="close" tabIndex="0" viewBox="0 0 24 24" preserveAspectRatio="xMidYMid meet" style={{"fill":"currentcolor", "verticalAlign": "middle", "width":"32px", "height":"32px"}}><g><path d="M19 6.41l-1.41-1.41-5.59 5.59-5.59-5.59-1.41 1.41 5.59 5.59-5.59 5.59 1.41 1.41 5.59-5.59 5.59 5.59 1.41-1.41-5.59-5.59z"></path></g></svg>
            </a>
            <h1>{I18n.t("application.greeting")}</h1>
            <p>{I18n.t("courses.invitation", title: @state.course.title)}</p>
            <p>
              <a href={"/users/auth/mediawiki?origin=" + window.location} className="button auth dark"><i className="icon icon-wiki-logo"></i> {I18n.t("application.log_in_extended")}</a>
              <a href={"/users/auth/mediawiki_signup?origin=" + window.location} className="button auth signup border"><i className="icon icon-wiki-logo"></i> {I18n.t("application.sign_up_extended")}</a>
            </p>
          </div>
        )
    else if @props.location.query.enrolled
      enroll_card = (
        <div className="module enroll">
          <a href={@_courseLinkParams()}>
            <svg className="close" tabIndex="0" viewBox="0 0 24 24" preserveAspectRatio="xMidYMid meet" style={{"fill":"currentcolor", "verticalAlign": "middle", "width":"32px", "height":"32px"}}><g><path d="M19 6.41l-1.41-1.41-5.59 5.59-5.59-5.59-1.41 1.41 5.59 5.59-5.59 5.59 1.41 1.41 5.59-5.59 5.59 5.59 1.41-1.41-5.59-5.59z"></path></g></svg>
          </a>
          <h1>{I18n.t("application.greeting2")}</h1>
          <p>{I18n.t("courses.join_successful", title: @state.course.title) if @state.course.title}</p>
        </div>
      )


    overviewLinkClassName = 'active' if @_onCourseIndex()

    <div>
      <div className="course-nav__wrapper">
        <Affix className="course_navigation" offset={57 + NotificationStore.getNotifications().length * 52}>
          <div className="container">
            {courseLink}
            <nav>
              <div className="nav__item" id="overview-link">
                <p><Link to="#{@_courseLinkParams()}/overview" className={overviewLinkClassName} activeClassName="active">{I18n.t("courses.overview")}</Link></p>
              </div>
              {timeline}
              <div className="nav__item" id="students-link">
                <p><Link to="#{@_courseLinkParams()}/students" activeClassName="active">{CourseUtils.i18n('students_short',@state.course.string_prefix)}</Link></p>
              </div>
              <div className="nav__item" id="articles-link">
                <p><Link to="#{@_courseLinkParams()}/articles" activeClassName="active">{I18n.t("articles.label")}</Link></p>
              </div>
              <div className="nav__item" id="uploads-link">
                <p><Link to="#{@_courseLinkParams()}/uploads" activeClassName="active">{I18n.t("uploads.label")}</Link></p>
              </div>
              <div className="nav__item" id="activity-link">
                <p><Link to="#{@_courseLinkParams()}/activity" activeClassName="active">{I18n.t("activity.label")}</Link></p>
              </div>
              {getHelp}
            </nav>
          </div>
        </Affix>
      </div>
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
