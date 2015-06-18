React             = require 'react/addons'
Expandable        = require '../highlevels/expandable'

StudentDrawer = React.createClass(
  displayName: 'StudentDrawer'
  getKey: ->
    'drawer_' + @props.student_id
  render: ->
    revisions = @props.revisions.map (rev) ->
      details = 'Chars Added: ' + rev.characters + ', Views: ' + rev.views
      <tr key={rev.id}>
        <td>
          <p className="name">
            <a href={rev.article.url} target="_blank" className="inline">{rev.article.title}</a>
            <br />
            <small className='tablet-only-ib'>{details}</small>
          </p>
        </td>
        <td className='desktop-only-tc'>{moment(rev.date).format('YYYY-MM-DD hh:mm')} UTC</td>
        <td className='desktop-only-tc'>{rev.characters}</td>
        <td className='desktop-only-tc'>{rev.views}</td>
        <td className='desktop-only-tc'>
          <a href={rev.url} target="_blank" className="inline">Dif.</a>
        </td>
      </tr>
    style =
      height: if @props.is_open then (40 + 71 * @props.revisions.length) else 0
      transition: 'height .2s'
    className = 'drawer'
    className += if !@props.is_open then ' closed' else ''

    <tr className={className}>
      <td colSpan="6">
        <div style={style}>
          <table className='list'>
            <thead>
              <tr>
                <th>User Contributions</th>
                <th className='desktop-only-tc'>Date / Time</th>
                <th className='desktop-only-tc'>Chars Added</th>
                <th className='desktop-only-tc'>Views</th>
                <th className='desktop-only-tc'></th>
              </tr>
            </thead>
            <tbody>{revisions}</tbody>
          </table>
        </div>
      </td>
    </tr>
)

module.exports = Expandable(StudentDrawer)