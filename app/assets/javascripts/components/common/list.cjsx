React               = require 'react'
TransitionGroup     = require '../../utils/TransitionGroup'
UIActions           = require '../../actions/ui_actions'

List = React.createClass(
  displayName: 'List'
  render: ->
    sorting = @props.store.getSorting()
    sortClass = if sorting.asc then 'asc' else 'desc'
    headers = []
    for key in Object.keys(@props.keys)
      key_obj = @props.keys[key]
      header_class = if sorting.key == key then sortClass else ''
      header_class += if key_obj['desktop_only'] then ' desktop-only-tc' else ''
      headers.push (
        <th
          onClick={UIActions.sort.bind(null, @props.table_key, key)}
          className={header_class}
          key={key}
          dangerouslySetInnerHTML={{__html: key_obj['label']}}></th>
      )

    <table className={@props.table_key}>
      <thead>
        <tr>
          {headers}
          <th></th>
        </tr>
      </thead>
      <TransitionGroup
        transitionName={@props.table_key}
        component='tbody'
        enterTimeout={500}
        leaveTimeout={500}
      >
        {@props.elements}
      </TransitionGroup>
    </table>
)

module.exports = List