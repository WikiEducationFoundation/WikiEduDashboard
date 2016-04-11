React               = require 'react'
TransitionGroup     = require 'react-addons-css-transition-group'
API                 = require '../../utils/api.coffee'
NotificationActions = require('../../actions/notification_actions.js').default
ReactRouter     = require 'react-router'
History         = ReactRouter.History
Link            = ReactRouter.Link
browserHistory  = ReactRouter.browserHistory

getReturnToParam = ->
  return_to = window.location.search.match(/return_to=([^&]*)/);
  return return_to && return_to[1] || "/"

getCurrentUser = ->
  $('#react_root').data('current_user')

# Router root
Root = React.createClass(
  render: ->
    return (
      <div className="container">
        <TransitionGroup
          transitionName="fade"
          component='div'
          transitionEnterTimeout={250}
          transitionLeaveTimeout={250}
        >
          {React.cloneElement(@props.children, { key: @props.location.pathname })}
        </TransitionGroup>
      </div>
    )
)

# Intro slide
Intro = React.createClass(
  getInitialState: ->
    user: getCurrentUser()

  render: ->
    return (
      <div className="intro text-center">
        <h1>Hi {@state.user.real_name || @state.user.username}</h1>
        <p>We’re excited that you’re here!</p>
        <Link to={{ pathname: '/onboarding/form', query: { return_to: decodeURIComponent(getReturnToParam()) } }}  className="button border inverse-border">Start <i className="icon icon-rt_arrow"></i></Link>
      </div>
    )
)

# Form slide
Form = React.createClass(
  getInitialState: ->
    user = getCurrentUser()
    return {
      started: false
      user: user
      name: user.real_name
      email: user.email
      instructor: if user.permissions? then String(user.permission == 2) else null
    }

  # Update state when input fields change
  _handleFieldChange: (field, e) ->
    @setState {
      "#{field}": e.target.value
    }

  _handleSubmit: (e) ->
    e.preventDefault()
    @setState sending: true
    @state.user.instructor = @state.instructor == 'true'
    $('#react_root').data('current_user', @state.user)

    API.onboard
      real_name: @state.name
      email: @state.email
      instructor: @state.instructor == 'true'
    .then () =>
      browserHistory.push('/onboarding/permissions?return_to=' + decodeURIComponent(getReturnToParam()))
    .catch (err) =>
      NotificationActions.addNotification
        message: I18n.t('error_500.explanation')
        closable: true
        type: 'error'
      @setState sending: false
      console.log(err, arguments)

  render: ->
    submitText = if @state.sending then 'Sending' else 'Submit'
    disabled = @state.sending
    return (
      <div className="form">
        <h1>Let’s get some business out of the way.</h1>
        <form className="panel" onSubmit={@_handleSubmit} ref="form">
          <div className="form-group">
            <label>Real name <span className="form-required-indicator">*</span></label>
            <input required className="form-control" type="text" name="name" defaultValue={@state.name} onChange={@_handleFieldChange.bind(this, 'name')}/>
            <p className="help-text">
              Your real name is not public. Its only seen by you, your intructor, and Wiki Ed admins.
            </p>
          </div>
          <div className="form-group">
            <label>Email <span className="form-required-indicator">*</span></label>
            <input required className="form-control" type="email" name="email" defaultValue={@state.email} onChange={@_handleFieldChange.bind(this, 'email')}/>
            <p className="help-text">
              Your email is only used for notifications and will not be shared.
            </p>
          </div>
          <div className="form-group">
            <label>Are you an instructor? <span className="form-required-indicator">*</span></label>
            <div className="radio-group">
              <div className={"radio-wrapped " + (if @state.instructor == 'true' then 'checked' else '')}>
                <label>
                  <input required type="radio" name="instructor" value="true" defaultChecked={@state.instructor == 'true'} onChange={@_handleFieldChange.bind(this, 'instructor')} />
                  Yes
                </label>
              </div>
              <div className={"radio-wrapped " + (if @state.instructor == 'false' then 'checked' else '')}>
                <label>
                  <input required type="radio" name="instructor" value="false" defaultChecked={@state.instructor == 'false'} onChange={@_handleFieldChange.bind(this, 'instructor')} />
                  No
                </label>
              </div>
            </div>
          </div>
          <button disabled={disabled} type="submit" className="button dark right">
            {submitText} <i className="icon icon-rt_arrow"></i>
          </button>
        </form>
      </div>
    )
)

# Permissions slide
Permissions = React.createClass(
  render: ->
    instructor =

    if getCurrentUser().instructor
      slide = (
        <div className="intro permissions">
          <h1>Permissions</h1>
          <p>
            Once you´ve signed in, this website will make automatic edits using your Wikipedia account, reflecting actions you take here. Your account will be used to update wiki pages when:
          </p>
          <ul>
            <li>you submit a Wikipedia classroom assignment or make edits to your course page</li>
            <li>you add or remove someone from a course</li>
            <li>you assign articles to students</li>
            <li>you send public messages to students</li>
          </ul>
          <p>All course content you contribute to to this website will be freely available under the <a href="http://creativecommons.org/licenses/by-sa/3.0/" target="_blank">Creative Commons Attribution-ShareAlike license</a> (the same one used by Wikipedia).</p>
          <Link to={{ pathname: '/onboarding/finish', query: { return_to: getReturnToParam() } }} className="button border inverse-border">
            Finish <i className="icon icon-rt_arrow"></i>
          </Link>
        </div>
      )
    else
      slide = (
        <div className="intro permissions">
          <h1>Permissions</h1>
          <p>
            Once you´ve signed in, this website will make automatic edits using your Wikipedia account, reflecting actions you take here. Your account will be used to update wiki pages to:
          </p>
          <ul>
            <li>set up a sandbox page where you can practice editing</li>
            <li>add a standard message on your userpage so that others know what course you are part of</li>
            <li>add standard messages to the Talk pages of articles you´re editing or reviewing</li>
            <li>update your course´s wiki page when you join the course or choose an assignment topic</li>
          </ul>
          <p>All course content you contribute to to this website will be freely available under the <a href="http://creativecommons.org/licenses/by-sa/3.0/" target="_blank">Creative Commons Attribution-ShareAlike license</a> (the same one used by Wikipedia).</p>
          <Link to={{ pathname: '/onboarding/finish', query: { return_to: getReturnToParam() } }} className="button border inverse-border">
            Finish <i className="icon icon-rt_arrow"></i>
          </Link>
        </div>
      )

    return slide
)

# Finished slide
Finished = React.createClass(

  getInitialState: ->
    return {}

  # When this route loads, wait a second then redirect out to the return_to param (or root)
  componentDidMount: ->
    @state.timeout = setTimeout(() =>
      return_to = getReturnToParam()
      window.location = decodeURIComponent(return_to)
    , 750)

  # clear the timeout just to be safe
  componentWillUnmount: ->
    clearTimeout(@state.timeout)

  render: ->
    return (
      <div className="intro">
        <h1>You´re all set. Thank you.</h1>
        <h2>Loading...</h2>
      </div>
    )
)

module.exports = {
  Root,
  Intro,
  Form,
  Permissions,
  Finished
}
