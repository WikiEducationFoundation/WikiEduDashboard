React             = require 'react/addons'

TextInput         = require '../common/text_input'
TextAreaInput     = require '../common/text_area_input'
Checkbox          = require '../common/checkbox'
Select            = require '../common/select'
BlockActions      = require '../../actions/block_actions'
GradeableActions  = require '../../actions/gradeable_actions'
Reorderable       = require '../highlevels/reorderable'

Block = React.createClass(
  displayName: 'Block'
  updateBlock: (value_key, value) ->
    to_pass = $.extend(true, {}, @props.block)
    to_pass[value_key] = value
    delete to_pass.deleteBlock
    BlockActions.updateBlock to_pass
  deleteBlock: ->
    BlockActions.deleteBlock @props.block.id
  updateGradeable: (value_key, value) ->
    if value == 'true'
      GradeableActions.addGradeable @props.block
    else
      GradeableActions.deleteGradeable @props.gradeable.id
  render: ->
    gradeable = @props.gradeable != undefined && !@props.gradeable.deleted
    className = 'block'
    if gradeable && !@props.editable
      dueDateRead = (
        <TextInput
          onChange={@updateBlock}
          value={@props.block.due_date}
          value_key={'due_date'}
          editable={@props.editable}
          type='date'
          label='Due'
          show=false
        />
      )
    if @props.editable
      deleteBlock = <button className='button danger right' onClick={@deleteBlock}>Delete Block</button>
      className += ' editable'
      className += ' dragging' if @props.isDragging
      graded = (
        <p>
          <span>Graded: </span>
          <Checkbox
            value={gradeable}
            onChange={@updateGradeable}
            value_key={'gradeable'}
            editable={@props.editable}
          />
        </p>
      )
    if (@props.block.kind < 3 && !@props.editable)
      spacer = <span>  —  </span>
    if @props.block.title || @props.editable
      title = (
        <span>
          {spacer}
          <TextInput
            onChange={@updateBlock}
            value={@props.block.title}
            value_key={'title'}
            editable={@props.editable}
            placeholder='Block title'
            spacer=' '
          />
          <TextInput
            onChange={@updateBlock}
            value={@props.block.due_date}
            value_key='due_date'
            editable={@props.editable}
            type='date'
            show={gradeable && @props.editable && false}
            spacer=' '
          />
        </span>
      )

    <li className={className}>
      <h4>
        <Select
          onChange={@updateBlock}
          value={@props.block.kind}
          value_key={'kind'}
          editable={@props.editable}
          options={['In Class', 'Assignment', 'Milestone', 'Custom']}
          show={@props.block.kind < 3 || @props.editable}
        />
        {title}
        {deleteBlock}
      </h4>
      {graded}
      {dueDateRead}
      <TextAreaInput
        onChange={@updateBlock}
        value={@props.block.content}
        value_key='content'
        editable={@props.editable}
        rows='4'
        hr=true
        placeholder='Block description'
        autoExpand=true
      />
    </li>
)

module.exports = Reorderable(Block, 'block', 'moveBlock')
