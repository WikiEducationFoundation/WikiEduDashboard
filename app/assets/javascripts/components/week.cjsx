React           = require 'react'
WeekStore       = require '../stores/week_store'
TimelineActions = require '../actions/timeline_actions'
Block           = require './block'
TextInput       = require './text_input'

getState = (course_slug, id) ->
  blocks: WeekStore.getBlocks(course_slug, id)

Week = React.createClass(
  displayName: 'Week'
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
  updateWeek: (value_key, value) ->
    to_pass = {}
    to_pass['id'] = this.props.id
    to_pass['title'] = value
    TimelineActions.updateWeek this.props.courseSlug, to_pass
  render: ->
    blocks = this.state.blocks.map (block, i) =>
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
      <TextInput
        onSave={this.updateWeek}
        value={this.props.title}
        value_key={'title'}
        editable={this.props.editable}
      />
      {deleteWeek}
      <ul className="list">
        {blocks}
        {addBlock}
      </ul>
    </li>
)

module.exports = Week