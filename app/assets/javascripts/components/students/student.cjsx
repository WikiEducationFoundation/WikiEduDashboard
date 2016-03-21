React             = require 'react'
ServerActions     = require '../../actions/server_actions.coffee'

AssignCell      = require './assign_cell.cjsx'

RevisionStore   = require '../../stores/revision_store.coffee'
UIStore         = require '../../stores/ui_store.coffee'
UIActions       = require '../../actions/ui_actions.coffee'

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
  _studentRole: 0
  _shouldShowRealName: ->
    return false unless @props.student.real_name?
    @props.current_user? && (@props.current_user.admin? || @props.current_user.role > @_studentRole())


  render: ->
    className = 'students'
    className += if @state.is_open then ' open' else ''
    if @props.student.course_training_progress?
      separator = <span className='tablet-only-ib'>&nbsp;|&nbsp;</span>
    chars = 'MS: ' + @props.student.character_sum_us + ', US: ' + @props.student.character_sum_us

    user_name = if @_shouldShowRealName() then (
      <span>
        <strong>{@props.student.real_name.trunc()}</strong>
        &nbsp;
        (<a onClick={@stop} href={@props.student.contribution_url} target="_blank" className="inline">
          {@props.student.username.trunc()}
        </a>)
      </span>
    ) else (
      <span><a onClick={@stop} href={@props.student.contribution_url} target="_blank" className="inline">
        {@props.student.username.trunc()}
      </a></span>
    )

    training_progress = if @props.student.course_training_progress then (
      <span className='red'>{@props.student.course_training_progress}</span>
    )

    <tr onClick={@openDrawer} className={className}>
      <td>
        <p className="name">
          {user_name}
          <br />
          <small>
            {training_progress}
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
      <td className='desktop-only-tc'>{@props.student.character_sum_ms} | {@props.student.character_sum_us}</td>
      <td style={{borderRight: '1px solid #ced1dd'}}><button onClick={@buttonClick} className="icon icon-arrow" ></button></td>
    </tr>
)

module.exports = Student
