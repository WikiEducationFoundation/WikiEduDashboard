React             = require 'react'
Editable          = require '../highlevels/editable'
TextInput         = require '../common/text_input'
TextAreaInput     = require '../common/text_area_input'
CourseStore       = require '../../stores/course_store'
CourseActions     = require '../../actions/course_actions'
ServerActions     = require '../../actions/server_actions'

getState = (course_id) ->
  course_tmp = CourseStore.getCourse()
  course:
    id: course_tmp.id
    school: course_tmp.school
    term: course_tmp.term
    start: course_tmp.start
    end: course_tmp.end

Details = React.createClass(
  displayName: 'Details'
  updateDetails: (value_key, value) ->
    to_pass = this.props.course
    to_pass[value_key] = value
    CourseActions.updateCourse to_pass
  render: ->
    <div>
      <p>{this.props.controls}</p>
      <p><span>{this.props.course.school}</span></p>
      <p><span>{this.props.course.term}</span></p>
      <p>
        <TextInput
          onChange={this.updateDetails}
          value={this.props.course.start}
          value_key={'start'}
          editable={this.props.editable}
        />
      </p>
      <p>
        <TextInput
          onChange={this.updateDetails}
          value={this.props.course.end}
          value_key={'end'}
          editable={this.props.editable}
        />
      </p>
    </div>
)

module.exports = Editable(Details, [CourseStore], ServerActions.saveCourse, getState)