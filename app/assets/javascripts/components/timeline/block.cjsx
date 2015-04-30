React           = require 'react'
TextInput       = require '../common/text_input'
TextAreaInput   = require '../common/text_area_input'
Checkbox        = require '../common/checkbox'
Select          = require '../common/select'
BlockActions    = require '../../actions/block_actions'

Block = React.createClass(
  displayName: 'Block'
  updateBlock: (value_key, value) ->
    to_pass = this.state
    to_pass[value_key] = value
    delete to_pass.deleteBlock  # this is mutating state?
    BlockActions.updateBlock to_pass
  render: ->
    is_graded = if this.props.is_gradeable == undefined then this.props.gradeable_id != null else this.props.is_gradeable
    if this.props.editable
      deleteBlock = <a onClick={this.props.deleteBlock}>Delete</a>

    <li className="block">
      {deleteBlock}
      <p>
        <Select
          onSave={this.updateBlock}
          value={this.props.kind}
          value_key={'kind'}
          editable={this.props.editable}
          options={['Assignment', 'Milestone', 'Class', 'Custom']}
        />
      </p>
      <p>
        <TextInput
          onSave={this.updateBlock}
          value={this.props.title}
          value_key={'title'}
          editable={this.props.editable}
        />
      </p>
      <p>
        <TextAreaInput
          onSave={this.updateBlock}
          value={this.props.content}
          value_key={'content'}
          editable={this.props.editable}
        />
      </p>
      <p><span>Graded: </span>
        <Checkbox
          value={is_graded}
          onSave={this.updateBlock}
          value_key={'is_gradeable'}
          editable={this.props.editable}
        />
      </p>
    </li>
)

module.exports = Block