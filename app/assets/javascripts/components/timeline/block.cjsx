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
    if confirm "Are you sure you want to delete this block? This will delete the block and all of its content.
      \n\nThis cannot be undone."
      BlockActions.deleteBlock @props.block.id
  _setEditable: ->
    BlockActions.setEditable @props.block.id
  _isEditable: ->
    @props.editable_block_ids?.indexOf(@props.block.id) >= 0
  updateGradeable: (value_key, value) ->
    if value == 'true'
      GradeableActions.addGradeable @props.block
    else
      GradeableActions.deleteGradeable @props.gradeable.id
  render: ->
    is_graded = @props.gradeable != undefined && !@props.gradeable.deleted
    className = 'block'
    className += " block-kind-#{@props.block.kind}"

    if @_isEditable()
      blockActions = (
        <div className="float-container block__block-actions">
          <button onClick={@props.saveBlockChanges.bind(null, @props.block.id)} className="button dark pull-right no-clear">Save</button>
          <span onClick={@props.cancelBlockEditable.bind(null, @props.block.id)} className="span-link pull-right no-clear">Cancel</span>
        </div>
      )


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
    if @_isEditable()
      deleteBlock = (<div className='delete-block-container'><button className='danger' onClick={@deleteBlock}>Delete Block</button></div>)
      className += ' editable'
      className += ' dragging' if @props.isDragging
      graded = (
        <Checkbox
          value={is_graded}
          onChange={@updateGradeable}
          value_key={'gradeable'}
          editable={@_isEditable()}
          label='Graded'
          container_class='graded'
        />
      )
    if (@props.block.kind < 3 && !@_isEditable())
      spacer = <span>  —  </span>

    modules = undefined
    if @props.block.training_modules || (parseInt(@props.block.kind) is 1 && @_isEditable())
      modules = (
        <TrainingModules
          onChange={@passedUpdateBlock}
          all_modules={@props.all_training_modules}
          block_modules={@props.block.training_modules}
          editable={@_isEditable()}
          block={@props.block}
        />
      )

    content = (
      <div>
        <TextAreaInput
          onChange={@updateBlock}
          value={@props.block.content}
          value_key='content'
          editable={@_isEditable()}
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

    <li className={className} draggable={@props.canDrag && @_isEditable()}>
      {blockActions}
      <div className="block__edit-button-container">
        <span className="pull-right button ghost-button block__edit-block" onClick={@_setEditable}>Edit</span>
      </div>
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
          editable={@_isEditable()}
          options={['In Class', 'Assignment', 'Milestone', 'Custom']}
          show={@props.block.kind < 3 || @_isEditable()}
          label='Block type'
          spacer=''
          popover_text={I18n.t('timeline.block_type')}
        />
      </p>
      <h4 className={"block-title" + (if @_isEditable() then " block-title--editing" else "")}>
        <TextInput
          onChange={@updateBlock}
          value={@props.block.title}
          value_key={'title'}
          editable={@_isEditable()}
          placeholder='Block title'
          show={@props.block.title  && !@_isEditable()}
          className='title pull-left'
          spacer=''
          onFocus={@props.toggleFocused}
          onBlur={@props.toggleFocused}
        />
        <TextInput
          onChange={@updateBlock}
          value={@props.block.title}
          value_key={'title'}
          editable={@_isEditable()}
          placeholder='Block title'
          label='Title'
          className='pull-left'
          spacer=''
          show={@_isEditable()}
          onFocus={@props.toggleFocused}
          onBlur={@props.toggleFocused}
        />
      </h4>
      <p className="block__block-due-date">
        <TextInput
          onChange={@updateBlock}
          value={@props.block.due_date}
          value_key='due_date'
          editable={@_isEditable()}
          type='date'
          label='Due date'
          spacer=''
          placeholder='Due date'
          isClearable=true
          show={@_isEditable() && parseInt(@props.block.kind) == 1}
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
