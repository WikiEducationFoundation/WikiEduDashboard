React             = require 'react/addons'
ServerActions     = require '../../actions/server_actions'

AssignCell      = require './assign_cell'

RevisionStore   = require '../../stores/revision_store'
UIStore         = require '../../stores/ui_store'
UIActions       = require '../../actions/ui_actions'

Student = React.createClass(
  displayName: 'Student'
  mixins: [UIStore.mixin]
  storeDidChange: ->
    @setState is_open: UIStore.getOpenKey() == ('drawer_' + @props.student.id)
  getInitialState: ->
    is_open: false
  stop: (e) ->
    e.stopPropagation()
  openDrawer: ->
    RevisionStore.clear()
    ServerActions.fetchRevisions(@props.student.id, @props.course.id)
    UIActions.open("drawer_#{@props.student.id}")
  buttonClick: (e) ->
    e.stopPropagation()
    @openDrawer()

  render: ->
    className = 'students'
    className += if @state.is_open then ' open' else ''
    unless @props.student.trained
      separator = <span className='tablet-only-ib'>&nbsp;|&nbsp;</span>
    chars = 'MS: ' + @props.student.character_sum_us + ', US: ' + @props.student.character_sum_us

    <tr onClick={@openDrawer} className={className}>
      <td>
        <div className="avatar">
          <img alt="User" src="/assets/images/user.svg" />
        </div>
        <p className="name">
          <span><a onClick={@stop} href={@props.student.contribution_url} target="_blank" className="inline">{@props.student.wiki_id.trunc()}</a></span>
          <br />
          <small>
            <span className='red'>{@props.student.course_training_progress}</span>
            {separator}
            <span className='tablet-only-ib'>{chars}</span>
          </small>
          <br />
          <span className='sandbox-link'><a onClick={@stop} href={@props.student.sandbox_url} target="_blank" className="inline">(sandboxes)</a></span>
        </p>
      </td>
      <td className='desktop-only-tc'>
        <AssignCell {...@props}
          role=0
          editable={@props.editable}
          assignments={@props.assigned}
        />
      </td>
      <td className='desktop-only-tc'>
        <AssignCell {...@props}
          role=1
          editable={@props.editable}
          assignments={@props.reviewing}
        />
      </td>
      <td className='desktop-only-tc'>{@props.student.recent_revisions}</td>
      <td className='desktop-only-tc'>{@props.student.character_sum_ms}</td>
      <td className='desktop-only-tc'>{@props.student.character_sum_us}</td>
      <td style={{borderRight: '1px solid #ced1dd'}}><button onClick={@buttonClick} className="icon icon-arrow" ></button></td>
    </tr>
)

module.exports = Student
