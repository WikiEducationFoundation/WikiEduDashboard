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
  updateDue: (value_key, value) ->
    difference = moment(value).diff(@props.week_start, 'days')
    @updateBlock(value_key, difference)
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
    if is_graded && !@props.editable
      dueDateRead = (
        <TextInput
          onChange={@updateDue}
          value={@props.week_start.clone().add(@props.block.duration, 'days').format("YYYY-MM-DD")}
          value_key={'duration'}
          editable={false}
          label='Due'
          show={is_graded && !@props.editable}
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
            show={!@props.editable}
            className='title'
          />
          <TextInput
            onChange={@updateBlock}
            value={@props.block.title}
            value_key={'title'}
            editable={@props.editable}
            placeholder='Block title'
            label='Title'
            show={@props.editable}
          />
          <TextInput
            onChange={@updateDue}
            value={@props.week_start.clone().add(@props.block.duration, 'days').format("YYYY-MM-DD")}
            value_key='duration'
            editable={@props.editable}
            type='date'
            label='Due date'
            show={is_graded && @props.editable}
            date_props={minDate: @props.week_start.clone().subtract(1, 'days')}
          />
        </span>
      )

    <li className={className}>
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
        placeholder='Block description'
        autoExpand=true
      />
    </li>
)

module.exports = Reorderable(Block, 'block', 'moveBlock')
