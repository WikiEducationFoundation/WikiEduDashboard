React           = require 'react'
WeekStore       = require './week_store'
TimelineActions = require './timeline_actions'
Block           = require './block'

getState = (course_slug, id) ->
  blocks: WeekStore.getBlocks(course_slug, id)

Week = React.createClass(
  mixins: [WeekStore.mixin]
  getInitialState: ->
    getState(this.props.courseSlug, this.props.id)
  storeDidChange: ->
    this.setState(getState(this.props.courseSlug, this.props.id))
  addBlock: ->
    TimelineActions.addBlock this.props.courseSlug, this.props.id,
      kind: 1
      content: 'This is a block'
      weekday: 2
  deleteBlock: (block_id) ->
    TimelineActions.deleteBlock this.props.id, block_id
  render: ->
    blocks = this.state.blocks.map (block, i) =>
      <Block {...block} key={block.id} deleteBlock={this.deleteBlock.bind(this, block.id)} />

    <li className="week row">
      <ul className="list">
        <li className="row view-all">
          <p>Week {this.props.index} - {this.props.title}</p>
          <a onClick={this.props.deleteWeek}>Delete</a>
          <a onClick={this.addBlock}>Add New Block</a>
        </li>
        {blocks}
        <li className="row view-all">
          <div>
            <a onClick={this.addBlock}>Add New Block</a>
          </div>
        </li>
      </ul>
    </li>
)

module.exports = Week