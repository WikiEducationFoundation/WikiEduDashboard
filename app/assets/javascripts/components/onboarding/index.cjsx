React         = require 'react'
Router        = require 'react-router'
RouteHandler  = Router.RouteHandler

Onboarding = React.createClass(
  displayName: 'Onboarding'

  getInitialState: ->
    return {
      started: false
      user: @_getCurrentUser()
    }

  _getCurrentUser: ->
    $('#react_root').data('current_user')

  _start: ->
    @setState {
      started: true
    }

  _renderIntro: ->
    return (
      <div className="intro text-center">
        <h1>Hi {@state.user.real_name}</h1>
        <p>We’re excited that you’re here!</p>
        <button onClick={@_start} className="button border inverse-border">Start <i className="icon icon-rt_arrow"></i></button>
      </div>
    )

  _renderForm: ->
    return (
      <div className="form">
        <h1>Let’s get some business out of the way.</h1>
        <form className="panel">
          <div className="form-group">
            <label>Real name</label>
            <input className="form-control" type="text"/>
            <p className="help-text">
              Your real name is not public. Its only seen by you, your intructor, and Wiki Ed admins.
            </p>
          </div>
          <div className="form-group">
            <label>Email</label>
            <input className="form-control" type="text"/>
            <p className="help-text">
              We only use your email legal lorem ipsum
            </p>
          </div>
          <div className="form-group">
            <label>Are you an instructor?</label>
            <div className="radio-group">
              <div className="radio-wrapped checked">
                <label>
                  <input type="radio" checked name="instructor" value="true"/>
                  Yes
                </label>
              </div>
              <div className="radio-wrapped">
                <label>
                  <input type="radio" name="instructor" value="false"/>
                  No
                </label>
              </div>
            </div>
          </div>
          <button className="button dark right">
            Submit <i className="icon icon-rt_arrow"></i>
          </button>
        </form>
      </div>
    )

  render: ->
    contents = undefined
    if !@state.started
      contents = @_renderIntro()
    else
      contents = @_renderForm()

    return (
      <div className="container">
        {contents}
      </div>
    )

)

module.exports = Onboarding
