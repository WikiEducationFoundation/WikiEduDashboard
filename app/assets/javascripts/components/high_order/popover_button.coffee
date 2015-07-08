React         = require 'react/addons'
Expandable    = require '../high_order/expandable'
Popover       = require '../common/popover'
Conditional   = require '../high_order/conditional'
ServerActions = require '../../actions/server_actions'

PopoverButton = (Key, ValueKey, Store, New, Items) ->
  format = (value) ->
    data = {}
    data[Key] = {}
    data[Key][ValueKey] = value
    return data
  component = React.createClass(
    displayname: Key.capitalize() + 'Button'
    mixins: [Store.mixin]
    storeDidChange: ->
      return unless @refs.entry?
      item = @refs.entry.getDOMNode().value
      if !New(item)
        alert 'Success!'
        @refs.entry.getDOMNode().value = ''
        @props.open()
    add: ->
      item = @refs.entry.getDOMNode().value
      if confirm 'Are you sure?'
        if New(item)
          ServerActions.add Key, @props.course_id, format(item)
        else
          alert 'That already exists for this course!'
    remove: (item_id) ->
      item = Store.getFiltered({ id: item_id })[0]
      if confirm 'Are you sure?'
        ServerActions.remove Key, @props.course_id, format(item[ValueKey])
    stop: (e) ->
      e.stopPropagation()
    getKey: ->
      Key + '_button'
    render: ->
      placeholder = Key.capitalize()
      edit_row = (
        <tr className='edit'>
          <td>
            <input type="text" ref='entry' placeholder={placeholder} />
            <button className='button border' onClick={@add}>Add</button>
          </td>
        </tr>
      )

      <div className='pop__container' onClick={@stop}>
        <button className='button border plus' onClick={@props.open}>+</button>
        <Popover
          is_open={@props.is_open}
          edit_row={edit_row}
          rows={Items(@props, @remove)}
        />
      </div>
  )
  return Conditional(Expandable(component))


module.exports = PopoverButton
