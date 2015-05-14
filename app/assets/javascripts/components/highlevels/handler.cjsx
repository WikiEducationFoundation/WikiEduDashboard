React = require 'react'
ServerActions = require '../../actions/server_actions'

# A common entry point for individual course pages
# Handles the initial API call based on the route

Handler = (Component) ->
  React.createClass(
    contextTypes:
      router: React.PropTypes.func.isRequired
    routeParams: ->
      @context.router.getCurrentParams()
    transitionTo: (to, params=null) ->
      @context.router.transitionTo(to, params || @routeParams())
    getCourseID: ->
      params = @context.router.getCurrentParams()
      return params.course_school + '/' + params.course_title
    getPermit: ->
      role = $('header.course-page').data('can_edit')
    getInitialState: ->
      ServerActions.fetchCourse @getCourseID()
      return {}
    render: ->
      <Component
        course_id={@getCourseID()}
        permit={@getPermit()}
      />
  )

module.exports = Handler