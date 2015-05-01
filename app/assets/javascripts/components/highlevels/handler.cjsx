React = require 'react'
ServerActions = require '../../actions/server_actions'

# A common entry point for individual course pages
# Handles the initial API call based on the route

Handler = (Component) ->
  React.createClass(
    contextTypes:
      router: React.PropTypes.func.isRequired
    getCourseID: ->
      params = this.context.router.getCurrentParams()
      return params.course_school + '/' + params.course_title
    getInitialState: ->
      ServerActions.fetchCourse this.getCourseID()
      return {}
    render: ->
      <Component course_id={this.getCourseID()} />
  )

module.exports = Handler