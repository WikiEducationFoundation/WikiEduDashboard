React             = require 'react/addons'
StudentActions    = require '../../actions/student_actions'

Student = React.createClass(
  displayName: 'Student'
  render: ->
    className = if @props.open then 'open' else ''
    <tr onClick={@props.onClick} className={className}>
      <td>
        <div className="avatar">
          <img alt="User" src="/images/user.svg" />
        </div>
        <p>{@props.student.wiki_id}</p>
      </td>
      <td>{@props.student.assignment_title}</td>
      <td>{@props.student.reviewer_name}</td>
      <td>{@props.student.character_sum_ms}</td>
      <td>{@props.student.character_sum_us}</td>
      <td><p className="icon icon-arrow"></p></td>
    </tr>
)

module.exports = Student