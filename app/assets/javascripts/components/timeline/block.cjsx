React             = require 'react'
TextInput         = require '../common/text_input'
TextAreaInput     = require '../common/text_area_input'
TrainingModules   = require '../training_modules'
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
  passedUpdateBlock: (_, modules) ->
    newBlock = $.extend(true, {}, @props.block)
    selectedIds = modules.map (module) -> module.value
    newBlock.training_module_ids = selectedIds
    BlockActions.updateBlock newBlock
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
    className += " block-kind-#{@props.block.kind}"
    if @props.block.due_date?
      dueDateRead = (
        <TextInput
          onChange={@updateBlock}
          value={@props.block.due_date}
          value_key={'due_date'}
          editable={false}
          label='Due'
          show={@props.block.due_date?}
          onFocus={@props.toggleFocused}
          onBlur={@props.toggleFocused}
        />
      )
    if @props.editable
      deleteBlock = (<div className='delete-block-container'><button className='danger' onClick={@deleteBlock}>Delete Block</button></div>)
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

    modules = undefined
    if @props.block.training_modules || (parseInt(@props.block.kind) is 1 && @props.editable)
      modules = (
        <TrainingModules
          onChange={@passedUpdateBlock}
          all_modules={@props.all_training_modules}
          block_modules={@props.block.training_modules}
          editable={@props.editable}
          block={@props.block}
        />
      )

    content = (
      <div>
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
          wysiwyg=true
        />
        {modules}
      </div>
    )

    <li className={className} draggable={@props.canDrag && @props.editable}>
      <div className="drag-handle">
        <div className="drag-handle__bar"></div>
        <div className="drag-handle__bar"></div>
        <div className="drag-handle__bar"></div>
      </div>
      <p className="block__block-type pull-right">
        <Select
          onChange={@updateBlock}
          value={@props.block.kind}
          value_key={'kind'}
          editable={@props.editable}
          options={['In Class', 'Assignment', 'Milestone', 'Custom']}
          show={@props.block.kind < 3 || @props.editable}
          label='Block type'
          spacer=''
          popover_text={I18n.t('timeline.block_type')}
        />
      </p>
      <h4 className={"block-title" + (if @props.editable then " block-title--editing" else "")}>
        <TextInput
          onChange={@updateBlock}
          value={@props.block.title}
          value_key={'title'}
          editable={@props.editable}
          placeholder='Block title'
          show={@props.block.title  && !@props.editable}
          className='title pull-left'
          spacer=''
          onFocus={@props.toggleFocused}
          onBlur={@props.toggleFocused}
        />
        <TextInput
          onChange={@updateBlock}
          value={@props.block.title}
          value_key={'title'}
          editable={@props.editable}
          placeholder='Block title'
          label='Title'
          className='pull-left'
          spacer=''
          show={@props.editable}
          onFocus={@props.toggleFocused}
          onBlur={@props.toggleFocused}
        />
      </h4>
      <p>
        <TextInput
          onChange={@updateBlock}
          value={@props.block.due_date}
          value_key='due_date'
          editable={@props.editable}
          type='date'
          label='Due date'
          spacer=''
          placeholder='Due date'
          isClearable=true
          show={@props.editable && parseInt(@props.block.kind) == 1}
          date_props={minDate: @props.week_start}
          onFocus={@props.toggleFocused}
          onBlur={@props.toggleFocused}
        />
      </p>
      {graded}
      {dueDateRead || (if is_graded then (<p>{I18n.t('timeline.due_default')}</p>) else '')}
      {content}
      {deleteBlock}
    </li>
)


module.exports = Block
#module.exports = Reorderable(Block, 'block', 'moveBlock')
