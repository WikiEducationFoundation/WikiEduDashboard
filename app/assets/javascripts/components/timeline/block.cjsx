React             = require 'react/addons'
DND               = require 'react-dnd'
TextInput         = require '../common/text_input'
TextAreaInput     = require '../common/text_area_input'
Checkbox          = require '../common/checkbox'
Select            = require '../common/select'
BlockActions      = require '../../actions/block_actions'
GradeableActions  = require '../../actions/gradeable_actions'

ItemTypes =
  BLOCK: 'block'

Block = React.createClass(
  displayName: 'Block'
  mixins: [DND.DragDropMixin]
  statics:
    configureDragDrop: (register, context) ->
      register(ItemTypes.BLOCK,
        dragSource:
          beginDrag: (component) ->
            item:
              block: component.props.block
        dropTarget:
          over: (component, item) ->
            component.props.moveBlock(item.block.id, component.props.block.id)
      )
  updateBlock: (value_key, value) ->
    to_pass = $.extend({}, this.props.block)
    to_pass[value_key] = value
    delete to_pass.deleteBlock
    BlockActions.updateBlock to_pass
  deleteBlock: ->
    BlockActions.deleteBlock this.props.block.id
  updateGradeable: (value_key, value) ->
    if value == 'true'
      GradeableActions.addGradeable this.props.block
    else
      GradeableActions.deleteGradeable this.props.gradeable.id
  render: ->
    gradeable = this.props.gradeable != undefined && !this.props.gradeable.deleted
    className = 'block'
    if gradeable && !this.props.editable
      dueDateRead = <p>
        <span>Due: </span>
        <TextInput
          onChange={this.updateBlock}
          value={this.props.block.due_date}
          value_key={'due_date'}
          editable={this.props.editable}
          type='date'
        />
      </p>
    if this.props.editable
      deleteBlock = <span className='button danger' onClick={this.deleteBlock}>Delete Block</span>
      dragSource = this.dragSourceFor(ItemTypes.BLOCK)
      dropTarget = this.dropTargetFor(ItemTypes.BLOCK)
      className += ' editable'
      className += ' dragging' if this.getDragState(ItemTypes.BLOCK).isDragging
      graded = <p>
        <span>Graded: </span>
        <Checkbox
          value={gradeable}
          onChange={this.updateGradeable}
          value_key={'gradeable'}
          editable={this.props.editable}
        />
      </p>
    style =
      top: 100 + this.props.block.order * (220 + 10)

    <li className={className} {...dragSource} {...dropTarget} style={style}>
      <h4>
        <Select
          onChange={this.updateBlock}
          value={this.props.block.kind}
          value_key={'kind'}
          editable={this.props.editable}
          options={['Assignment', 'Milestone', 'Class', 'Custom']}
        />
        &nbsp;&nbsp;&mdash;&nbsp;&nbsp;
        <TextInput
          onChange={this.updateBlock}
          value={this.props.block.title}
          value_key={'title'}
          editable={this.props.editable}
        />
        <TextInput
          onChange={this.updateBlock}
          value={this.props.block.due_date}
          value_key={'due_date'}
          editable={this.props.editable}
          type='date'
          show={gradeable && this.props.editable}
        />
        {deleteBlock}
      </h4>
      {graded}
      {dueDateRead}
      <TextAreaInput
        onChange={this.updateBlock}
        value={this.props.block.content}
        value_key={'content'}
        editable={this.props.editable}
        hr=true
      />
    </li>
)

module.exports = Block