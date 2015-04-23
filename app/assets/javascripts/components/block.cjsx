React           = require 'react'
TextInput       = require './text_input'
TextAreaInput   = require './text_area_input'
Checkbox        = require './checkbox'
TimelineActions = require '../actions/timeline_actions'

Block = React.createClass(
  displayName: 'Block'
  getInitialState: ->
    this.props
  updateBlock: (value_key, value) ->
    to_pass = this.state
    to_pass[value_key] = value
    delete to_pass.deleteBlock
    TimelineActions.updateBlock this.props.week_id, to_pass
  render: ->
    if this.props.editable
      deleteBlock = <a onClick={this.props.deleteBlock}>Delete</a>

    <li className="block">
      {deleteBlock}
      <p>{this.props.kind}</p>
      <TextInput
        onSave={this.updateBlock}
        value={this.props.title}
        value_key={'title'}
        editable={this.props.editable}
      />
      <TextAreaInput
        onSave={this.updateBlock}
        value={this.props.content}
        value_key={'content'}
        editable={this.props.editable}
      />
      <Checkbox
        value={this.props.gradeable_id != null}
        onSave={this.updateBlock}
        value_key={'is_gradeable'}
        editable={this.props.editable}
      />
    </li>
)

module.exports = Block