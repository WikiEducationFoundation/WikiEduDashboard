React             = require 'react'
TextInput         = require '../common/text_input'
TextAreaInput     = require '../common/text_area_input'
Checkbox          = require '../common/checkbox'
Select            = require '../common/select'
BlockActions      = require '../../actions/block_actions'
GradeableActions  = require '../../actions/gradeable_actions'

Block = React.createClass(
  displayName: 'Block'
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
    if this.props.editable
      deleteBlock = <a onClick={this.deleteBlock}>Delete</a>

    <li className="block">
      {deleteBlock}
      <p>
        <Select
          onChange={this.updateBlock}
          value={this.props.block.kind}
          value_key={'kind'}
          editable={this.props.editable}
          options={['Assignment', 'Milestone', 'Class', 'Custom']}
        />
      </p>
      <p>
        <TextInput
          onChange={this.updateBlock}
          value={this.props.block.title}
          value_key={'title'}
          editable={this.props.editable}
        />
      </p>
      <p>
        <TextAreaInput
          onChange={this.updateBlock}
          value={this.props.block.content}
          value_key={'content'}
          editable={this.props.editable}
        />
      </p>
      <p><span>Graded: </span>
        <Checkbox
          value={gradeable}
          onChange={this.updateGradeable}
          value_key={'gradeable'}
          editable={this.props.editable}
        />
      </p>
    </li>
)

module.exports = Block