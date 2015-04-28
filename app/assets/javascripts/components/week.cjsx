React           = require 'react'
TimelineActions = require '../actions/timeline_actions'
Block           = require './block'
TextInput       = require './text_input'

Week = React.createClass(
  displayName: 'Week'
  addBlock: ->
    TimelineActions.addBlock this.props.id
  deleteBlock: (block_id) ->
    TimelineActions.deleteBlock this.props.id, block_id
  updateWeek: (value_key, value) ->
    to_pass = {}
    to_pass['id'] = this.props.id
    to_pass['title'] = value
    to_pass['blocks'] = this.props.blocks
    to_pass['is_new'] = this.props.is_new
    TimelineActions.updateWeek to_pass
  render: ->
    blocks = this.props.blocks.map (block, i) =>
      unless block.deleted
        <Block {...block}
          key={block.id}
          editable={this.props.editable}
          deleteBlock={this.deleteBlock.bind(this, block.id)}
        />
    if this.props.editable
      addBlock = <li className="row view-all">
                    <div>
                      <a onClick={this.addBlock}>Add New Block</a>
                    </div>
                  </li>
      deleteWeek = <a onClick={this.props.deleteWeek}>Delete week</a>

    <li className="week">
      <p>Week {this.props.index}</p>
      <p><TextInput
        onSave={this.updateWeek}
        value={this.props.title}
        value_key={'title'}
        editable={this.props.editable}
      /></p>
      {deleteWeek}
      <ul className="list">
        {blocks}
        {addBlock}
      </ul>
    </li>
)

module.exports = Week