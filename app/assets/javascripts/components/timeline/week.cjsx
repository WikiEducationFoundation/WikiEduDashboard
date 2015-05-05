React           = require 'react'
Block           = require './block'
BlockActions    = require '../../actions/block_actions'
WeekActions     = require '../../actions/week_actions'
BlockStore      = require '../../stores/block_store'
GradeableStore  = require '../../stores/gradeable_store'
TextInput       = require '../common/text_input'

Week = React.createClass(
  displayName: 'Week'
  addBlock: ->
    BlockActions.addBlock this.props.week.id
  deleteBlock: (block_id) ->
    BlockActions.deleteBlock block_id
  moveBlock: (block_id, after_block_id) ->
    block = $.grep(this.props.blocks, (b) -> b.id == block_id)[0]
    after_block = $.grep(this.props.blocks, (b) -> b.id == after_block_id)[0]

    console.log block.order
    console.log after_block.order
    old_order = block.order
    block.order = after_block.order
    after_block.order = old_order
    console.log block.order
    console.log after_block.order
    console.log '-----'

    BlockActions.updateBlock block, true
    BlockActions.updateBlock after_block
  updateWeek: (value_key, value) ->
    to_pass = $.extend({}, this.props.week)
    to_pass['title'] = value
    WeekActions.updateWeek to_pass
  render: ->
    blocks = this.props.blocks.map (block, i) =>
      unless block.deleted
        <Block
          block={block}
          key={block.id}
          editable={this.props.editable}
          gradeable={GradeableStore.getGradeableByBlock(block.id)}
          deleteBlock={this.deleteBlock.bind(this, block.id)}
          moveBlock={this.moveBlock}
        />
    blocks.sort (a, b) ->
      a.props.block.order - b.props.block.order
    if this.props.editable
      addBlock = <li className="row view-all">
                    <div>
                      <a onClick={this.addBlock}>Add New Block</a>
                    </div>
                  </li>
      deleteWeek = <a onClick={this.props.deleteWeek}>Delete week</a>

    <li className="week">
      <p>
        <span>Week {this.props.index}&nbsp;&nbsp;&mdash;&nbsp;&nbsp;</span>
        <TextInput
          onChange={this.updateWeek}
          value={this.props.week.title}
          value_key={'title'}
          editable={this.props.editable}
        />
      </p>
      {deleteWeek}
      <ul className="list">
        {blocks}
        {addBlock}
      </ul>
    </li>
)

module.exports = Week