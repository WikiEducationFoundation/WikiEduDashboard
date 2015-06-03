React             = require 'react/addons'
StudentActions    = require '../../actions/student_actions'

Student = React.createClass(
  displayName: 'Student'
  render: ->
    className = 'student'
    className += if @props.open then ' open' else ''
    className += if @props.student.revisions.length == 0 then ' no_revisions' else ''
    trained = if @props.student.trained then '' else 'Training Incomplete'
    unless @props.student.trained
      separator = <span className='tablet-only-ib'>&nbsp;|&nbsp;</span>
    chars = 'MS: ' + @props.student.character_sum_us + ', US: ' + @props.student.character_sum_us
    <tr onClick={@props.onClick} className={className}>
      <td>
        <div className="avatar">
          <img alt="User" src="/images/user.svg" />
        </div>
        <p className="name">
          <span>{@props.student.wiki_id}</span>
          <br />
          <small>
            <span className='red'>{trained}</span>
            {separator}
            <span className='tablet-only-ib'>{chars}</span>
          </small>
        </p>
      </td>
      <td className='desktop-only-tc'>{@props.student.assignment_title}</td>
      <td className='desktop-only-tc'>{@props.student.reviewer_name}</td>
      <td className='desktop-only-tc'>{@props.student.character_sum_ms}</td>
      <td className='desktop-only-tc'>{@props.student.character_sum_us}</td>
      <td><p className="icon icon-arrow"></p></td>
    </tr>
)

module.exports = Student