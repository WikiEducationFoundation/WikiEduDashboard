React         = require 'react'
Router        = require 'react-router'
CourseLink    = require '../common/course_link'

StudentStore    = require '../../stores/student_store'
StudentActions  = require '../../actions/student_actions'
ServerActions   = require '../../actions/server_actions'

Modal         = require '../common/modal'
TextInput     = require '../common/text_input'

AddStudent = React.createClass(
  displayName: 'AddStudent'
  mixins: [StudentStore.mixin]
  storeDidChange: ->
    wiki_id = @refs.wiki_id.getDOMNode().value
    student_obj = { wiki_id: wiki_id }
    if StudentStore.getFiltered({ wiki_id: wiki_id }).length > 0
      alert (wiki_id + ' successfully enrolled!')
      @props.transitionTo 'students'
  saveStudent: ->
    wiki_id = @refs.wiki_id.getDOMNode().value
    student_obj = { wiki_id: wiki_id, role: 0 }
    if StudentStore.getFiltered({ wiki_id: wiki_id }).length == 0
      ServerActions.enrollStudent student_obj, @props.course_id
    else
      alert 'That student is already enrolled!'
  render: ->
    <Modal>
      <div className="active">
        <h3>Add a student</h3>
        <input ref='wiki_id' type='text' />
        <div className='wizard__panel__controls'>
          <div className='left'></div>
          <div className='right'>
            <CourseLink className="button" to="students">Cancel</CourseLink>
            <div className='button dark' onClick={@saveStudent}>Add student</div>
          </div>
        </div>
      </div>
    </Modal>
)

module.exports = AddStudent
