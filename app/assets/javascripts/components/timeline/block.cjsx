React             = require 'react/addons'

TextInput         = require '../common/text_input'
TextAreaInput     = require '../common/text_area_input'
Checkbox          = require '../common/checkbox'
Select            = require '../common/select'
BlockActions      = require '../../actions/block_actions'
GradeableActions  = require '../../actions/gradeable_actions'
Reorderable       = require '../high_order/reorderable'

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
    is_graded = @props.gradeable != undefined && !@props.gradeable.deleted
    className = 'block'
    if @props.block.due_date?
      dueDateRead = (
        <TextInput
          onChange={@updateBlock}
          value={moment(@props.block.due_date).format("YYYY-MM-DD")}
          value_key={'due_date'}
          editable={false}
          label='Due'
          show={@props.block.due_date?}
          onFocus={@props.toggleFocused}
          onBlur={@props.toggleFocused}
        />
      )
    if @props.editable
      deleteBlock = <button className='button danger right' onClick={@deleteBlock}>Delete Block</button>
      className += ' editable'
      className += ' dragging' if @props.isDragging
      graded = (
        <Checkbox
          value={is_graded}
          onChange={@updateGradeable}
          value_key={'gradeable'}
          editable={@props.editable}
          label='Graded'
          container_class='graded'
        />
      )
    if (@props.block.kind < 3 && !@props.editable)
      spacer = <span>  —  </span>

    <li className={className} draggable={@props.canDrag && @props.editable}>
      <div className="drag-handle">
        <div className="drag-handle__bar"></div>
        <div className="drag-handle__bar"></div>
        <div className="drag-handle__bar"></div>
      </div>
      <h4>
        <Select
          onChange={@updateBlock}
          value={@props.block.kind}
          value_key={'kind'}
          editable={@props.editable}
          options={['In Class', 'Assignment', 'Milestone', 'Custom']}
          show={@props.block.kind < 3 || @props.editable}
          label='Block Type'
          inline=true
        />
        {spacer}
        <TextInput
          onChange={@updateBlock}
          value={@props.block.title}
          value_key={'title'}
          editable={@props.editable}
          placeholder='Block title'
          spacer=' '
          show={@props.block.title  && !@props.editable}
          className='title'
          onFocus={@props.toggleFocused}
          onBlur={@props.toggleFocused}
          inline=true
        />
        <TextInput
          onChange={@updateBlock}
          value={@props.block.title}
          value_key={'title'}
          editable={@props.editable}
          placeholder='Block title'
          label='Title'
          show={@props.editable}
          onFocus={@props.toggleFocused}
          onBlur={@props.toggleFocused}
          inline=true
        />
        <TextInput
          onChange={@updateBlock}
          value={@props.block.due_date}
          value_key='due_date'
          editable={@props.editable}
          type='date'
          label='Due date'
          placeholder='Due date'
          inline=true
          isClearable=true
          show={@props.editable && parseInt(@props.block.kind) == 1}
          date_props={minDate: @props.week_start.clone().subtract(1, 'days')}
          onFocus={@props.toggleFocused}
          onBlur={@props.toggleFocused}
        />
        {deleteBlock}
      </h4>
      {graded}
      {dueDateRead || (if is_graded then (<p>{I18n.t('timeline.due_default')}</p>) else '')}
      <TextAreaInput
        onChange={@updateBlock}
        value={@props.block.content}
        value_key='content'
        editable={@props.editable}
        rows='4'
        placeholder='Block description'
        autoExpand=true
        onFocus={@props.toggleFocused}
        onBlur={@props.toggleFocused}
      />
    </li>
)

module.exports = Reorderable(Block, 'block', 'moveBlock')
