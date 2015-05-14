# React           = require 'react'
# TimelineStore   = require '../../stores/timeline_store'
# TimelineActions = require '../../actions/timeline_actions'
# EditableInterface = require '../common/editable_interface.jsx'

# TextInput       = require '../common/text_input'
# TextAreaInput   = require '../common/text_area_input'

# getState = (course_id) ->
#   blocks: TimelineStore.getBlocks(course_id)

# Grading = React.createClass(
#   displayName: 'Grading'
#   updateBlock: (block, points) ->
#     block['points'] = points
#     TimelineActions.updateBlock block_id, block
#   render: ->
#     console.log @props
#     blocks = @props.blocks.map (block, i) =>
#       <p>
#         <span>{block.title}</span>
#         <TextInput
#           onSave={@updateBlock}
#           value={block.points}
#           value_key={block}
#           editable={@props.editable}
#         />
#       </p>
#     <div>
#       <p>{@props.controls()}</p>
#       {blocks}
#     </div>
# )

# module.exports = EditableInterface(Grading, TimelineStore, getState, TimelineActions)