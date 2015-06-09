React             = require 'react/addons'

Revision = React.createClass(
  displayName: 'Revision'
  render: ->
    chars = 'Chars Added: ' + @props.revision.characters
    ratingClass = 'rating ' + @props.revision.rating
    ratingMobileClass = ratingClass + ' tablet-only'

    <tr className='revision'>
      <td className='popover-trigger desktop-only-tc'>
        <p className='rating_num hidden'>{@props.revision.rating_num}</p>
        <div className={ratingClass}><p>{@props.revision.pretty_rating || '-'}</p></div>
        <div className='popover dark'>
          <p>Copy here</p>
        </div>
      </td>
      <td>
        <div className={ratingMobileClass}><p>{@props.revision.pretty_rating}</p></div>
        <a onClick={@stop} href={@props.revision.article_url} target='_blank' className='inline'>{@props.revision.title}</a>
      </td>
      <td className='desktop-only-tc'>{@props.revision.revisor}</td>
      <td className='desktop-only-tc'>{@props.revision.characters}</td>
      <td className='desktop-only-tc'>{moment(@props.revision.date).format('YYYY-MM-DD hh:mm')} UTC</td>
      <td>
        <a className='inline' href={@props.revision.url} target='_blank'>Diff</a>
      </td>
    </tr>
)

module.exports = Revision