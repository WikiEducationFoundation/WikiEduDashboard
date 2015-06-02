React             = require 'react/addons'
StudentActions    = require '../../actions/student_actions'

StudentDrawer = React.createClass(
  displayName: 'StudentDrawer'
  render: ->
    revisions = @props.revisions.map (rev) ->
      <tr key={rev.id}>
        <td>{rev.article.title}</td>
        <td>{moment(rev.date).format('YYYY-MM-DD hh:mm')}</td>
        <td>{rev.characters}</td>
        <td>{rev.views}</td>
        <td></td>
      </tr>
    style =
      height: if @props.open then (40 + 71 * @props.revisions.length) else 0
      transition: 'height .2s'

    className = 'drawer'
    className += if !@props.open then ' closed' else ''
    <tr className={className}>
      <td colSpan="6">
        <div style={style}>
          <table>
            <thead>
              <tr>
                <th>User Contributions</th>
                <th>Date / Time</th>
                <th>Chars Added</th>
                <th>Views</th>
                <th></th>
              </tr>
            </thead>
            <tbody>{revisions}</tbody>
          </table>
        </div>
      </td>
    </tr>
)

module.exports = StudentDrawer