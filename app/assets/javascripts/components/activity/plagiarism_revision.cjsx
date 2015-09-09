React     = require 'react/addons'
UIStore   = require '../../stores/ui_store'
UIActions = require '../../actions/ui_actions'

PlagiarismRevision = React.createClass
  mixins: [UIStore.mixin]
  storeDidChange: ->
    @setState is_open: UIStore.getOpenKey() == ('drawer_' + @props.articleId)
  getInitialState: ->
    is_open: false
  openDrawer: ->
    UIActions.open("drawer_#{@props.articleId}")
  render: ->
    className = 'suspected-plagiarism-revision'
    className += if @state.is_open then ' open' else ' closed'

    <tr className={className} onClick={@openDrawer} key={@props.key}>
      <td>
        <a href={@props.articleUrl}>{@props.title}</a>
      </td>
      <td>
        <a href={@props.reportUrl}>Report</a>
      </td>
      <td>
        {@props.author}
      </td>
      <td>
        {@props.revisionDateTime}
      </td>
      <td>
        <button className='icon icon-arrow'></button>
      </td>
    </tr>

module.exports = PlagiarismRevision
