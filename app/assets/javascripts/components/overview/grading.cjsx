React           = require 'react'

getState = (course_id) ->
  blocks: BlockStore.getBlocks()

Grading = React.createClass(
  displayName: 'Grading'
  render: ->
    blocks = @props.blocks.map (block, i) =>
      <p>
        <span>{block.title}: </span>
      </p>
    <div>
      {blocks}
    </div>
)

module.exports = Grading