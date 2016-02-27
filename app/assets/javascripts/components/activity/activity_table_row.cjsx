React     = require 'react'
UIStore   = require '../../stores/ui_store.coffee'
UIActions = require '../../actions/ui_actions.coffee'

ActivityTableRow = React.createClass
  mixins: [UIStore.mixin]
  storeDidChange: ->
    @setState is_open: UIStore.getOpenKey() == ('drawer_' + @props.rowId)
  getInitialState: ->
    is_open: false
  openDrawer: ->
    UIActions.open("drawer_#{@props.rowId}")
  render: ->
    className = 'activity-table-row'
    className += if @state.is_open then ' open' else ' closed'
    if @props.diffUrl
      revisionDateTime = (
        <a href={@props.diffUrl}>{@props.revisionDateTime}</a>
      )
    else
      revisionLink = @props.revisionDateTime

    if @props.revisionScore
      col2 = (
        <td>
          {@props.revisionScore}
        </td>
      )
    if @props.reportUrl
      col2 = (
        <td>
          <a href={@props.reportUrl} target="_blank">Report</a>
        </td>
      )


    <tr className={className} onClick={@openDrawer} key={@props.key}>
      <td>
        <a href={@props.articleUrl}>{@props.title}</a>
      </td>
      {col2}
      <td>
        <a href={@props.talkPageLink}>{@props.author}</a>
      </td>
      <td>
        {revisionDateTime}
      </td>
      <td>
        <button className='icon icon-arrow'></button>
      </td>
    </tr>

module.exports = ActivityTableRow
