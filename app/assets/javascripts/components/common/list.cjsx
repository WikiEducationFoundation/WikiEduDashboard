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
      unless (@props.sortable? && !@props.sortable) || (key_obj['sortable']? && !key_obj['sortable'])
        header_class += ' sortable'
        header_onclick = UIActions.sort.bind(null, @props.table_key, key)
      else
        header_onclick = null
      headers.push (
        <th
          onClick={header_onclick}
          className={header_class}
          key={key}
          dangerouslySetInnerHTML={{__html: key_obj['label']}}></th>
      )
      className = @props.table_key + ' list'

    elements = @props.elements
    if elements.length == 0
      if @props.store.isLoaded()
        text = 'This course has no ' + @props.table_key
      else
        text = 'Loading ' + @props.table_key + '...'
      elements = (
        <tr>
          <td colSpan={headers.length + 1} className='text-center'>
            <span>{text}</span>
          </td>
        </tr>
      )

    <table className={className}>
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
        {elements}
      </TransitionGroup>
    </table>
)

module.exports = List