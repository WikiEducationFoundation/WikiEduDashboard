React         = require 'react'
TransitionGroup = require 'react-addons-css-transition-group'
API     = require '../../utils/api'

Onboarding = React.createClass(
  displayName: 'Onboarding'

  getInitialState: ->
    user = @_getCurrentUser()
    return {
      started: false
      user: user
      name: user.real_name
      email: user.email
    }


  # Pull user from react root
  _getCurrentUser: ->
    $('#react_root').data('current_user')


  # Update state when input fields change
  _handleFieldChange: (field, e) ->
    @setState {
      "#{field}": e.target.value
    }


  # Post updates to user API and transition out
  _handleSubmit: (e) ->
    e.preventDefault()

    @setState slide: 'finished'

    API.onboard
      real_name: @state.name
      email: @state.email
    .then (res) ->
      setTimeout () ->
        document.location.href = "/"
      , 750
    .catch((err) =>
      console.log(err, arguments)
      @setState slide: 'form'
    )


  # Handle start button click, transition to form
  _handleStart: ->
    @setState slide: 'form'


  # Render finished slide
  _renderFinishedSlide: ->
    return (
      <div key="finished" className="intro text--center">
        <h1>Thank you.</h1>
        <h2>Loading dashboard...</h2>
      </div>
    )


  # Render form slide
  _renderFormSlide: ->
    return (
      <div key="form" className="form">
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
                  <input required type="radio" name="instructor" value="true" onChange={@_handleFieldChange.bind(this, 'instructor')} />
                  Yes
                </label>
              </div>
              <div className={"radio-wrapped " + (if @state.instructor == 'false' then 'checked' else '')}>
                <label>
                  <input required type="radio" name="instructor" value="false" onChange={@_handleFieldChange.bind(this, 'instructor')} />
                  No
                </label>
              </div>
            </div>
          </div>
          <button type="submit" className="button dark right">
            Submit <i className="icon icon-rt_arrow"></i>
          </button>
        </form>
      </div>
    )


  # Render intro/welcome slide
  _renderIntroSlide: ->
    return (
      <div key="intro" className="intro text-center">
        <h1>Hi {@state.user.real_name || @state.user.wiki_id}</h1>
        <p>We’re excited that you’re here!</p>
        <button onClick={@_handleStart} className="button border inverse-border">Start <i className="icon icon-rt_arrow"></i></button>
      </div>
    )


  # Render
  render: ->
    switch @state.slide
      when 'finished'
        contents = @_renderFinishedSlide()
      when 'form'
        contents = @_renderFormSlide()
      else
        contents = @_renderIntroSlide()

    return (
      <div className="container">
        <TransitionGroup
          transitionName="fade"
          component='div'
          transitionEnterTimeout={250}
          transitionLeaveTimeout={250}
        >
          {contents}
        </TransitionGroup>
      </div>
    )

)

module.exports = Onboarding
