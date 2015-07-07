React         = require 'react/addons'
Expandable    = require '../highlevels/expandable'
Popover       = require '../common/popover'
ServerActions = require '../../actions/server_actions'
Conditional   = require '../highlevels/conditional'
TagStore      = require '../../stores/tag_store'

TagButton = React.createClass(
  displayname: 'TagButton'
  mixins: [TagStore.mixin]
  storeDidChange: ->
    return unless @refs.tag?
    tag = @refs.tag.getDOMNode().value
    if TagStore.getFiltered({ tag: tag }).length > 0
      alert (tag + ' successfully added!')
      @refs.tag.getDOMNode().value = ''
      @props.open()
  addTag: ->
    tag = @refs.tag.getDOMNode().value
    if confirm 'Are you sure you want to add the ' + tag + ' tag to this course?'
      if TagStore.getFiltered({ tag: tag }).length == 0
        ServerActions.addTag @props.course_id, tag
      else
        alert 'This course already has that tag!'
  removeTag: (tag_id) ->
    tag = TagStore.getFiltered({ id: tag_id })[0]
    if confirm 'Are you sure you want to remove the ' + tag.tag + ' tag from this course?'
      ServerActions.removeTag @props.course_id, tag.tag
  stop: (e) ->
    e.stopPropagation()
  getKey: ->
    'tag_button'
  render: ->
    tags = @props.tags.map (tag) =>
      remove_button = (
        <button className='button border plus' onClick={@removeTag.bind(@, tag.id)}>-</button>
      ) unless tag.key?
      <tr key={tag.id + '_tag'}>
        <td>{tag.tag}{remove_button}</td>
      </tr>

    edit_row = (
      <tr className='edit'>
        <td>
          <input type="text" ref='tag' placeholder='Tag' />
          <button className='button border' onClick={@addTag}>Add</button>
        </td>
      </tr>
    )

    <div className='pop__container' onClick={@stop}>
      <button className='button border plus' onClick={@props.open}>+</button>
      <Popover
        is_open={@props.is_open}
        edit_row={edit_row}
        rows={tags}
      />
    </div>
)

module.exports = Conditional(Expandable(TagButton))
