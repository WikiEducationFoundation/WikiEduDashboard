React         = require 'react'
PopoverButton = require '../high_order/popover_button.cjsx'
TagStore      = require '../../stores/tag_store.coffee'

tagIsNew = (tag) ->
  TagStore.getFiltered({ tag: tag }).length == 0

tags = (props, remove) ->
  props.tags.map (tag) =>
    remove_button = (
      <button className='button border plus' onClick={remove.bind(null, tag.id)}>-</button>
    )
    <tr key={tag.id + '_tag'}>
      <td>{tag.tag}{remove_button}</td>
    </tr>

module.exports = PopoverButton('tag', 'tag', TagStore, tagIsNew, tags)
