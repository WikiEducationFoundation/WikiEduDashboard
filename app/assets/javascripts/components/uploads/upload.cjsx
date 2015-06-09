React = require 'react/addons'

Upload = React.createClass(
  displayName: 'Upload'
  render: ->
    if @props.upload.usages > 0
      details = (
        <p className='tablet-only'>
          <span>{@props.upload.uploader}</span>
          <span>&nbsp;|&nbsp;</span>
          <span>Usages: {@props.upload.usages}</span>
        </p>
      )
    else
      details = (
        <p className='tablet-only'><span>{@props.upload.uploader}</span></p>
      )

    <tr className='upload'>
      <td>
        <a href={@props.upload.url} target="_blank">
          <img src={@props.upload.thumburl} />
        </a>
        {details}
      </td>
      <td className="desktop-only-tc">
        <a href={@props.upload.url} target="_blank" className="inline">{@props.upload.file_name}</a>
      </td>
      <td className="desktop-only-tc">{@props.upload.uploader}</td>
      <td className="desktop-only-tc">{@props.upload.usage_count}</td>
      <td className="desktop-only-tc">{moment(@props.upload.uploaded_at).format('YYYY-MM-DD hh:mm')} UTC</td>
      <td></td>
    </tr>
)

module.exports = Upload
