React           = require 'react/addons'
DND             = require 'react-dnd'
Block           = require './block'
BlockActions    = require '../../actions/block_actions'
WeekActions     = require '../../actions/week_actions'
BlockStore      = require '../../stores/block_store'
GradeableStore  = require '../../stores/gradeable_store'
TextInput       = require '../common/text_input'

ReactCSSTG      = React.addons.CSSTransitionGroup

Week = React.createClass(
  displayName: 'Week'
  addBlock: ->
    BlockActions.addBlock @props.week.id
  deleteBlock: (block_id) ->
    BlockActions.deleteBlock block_id
  updateWeek: (value_key, value) ->
    to_pass = $.extend({}, @props.week)
    to_pass['title'] = value
    WeekActions.updateWeek to_pass
  render: ->
    blocks = @props.blocks.map (block, i) =>
      unless block.deleted
        <Block
          block={block}
          key={block.id}
          editable={@props.editable}
          gradeable={GradeableStore.getGradeableByBlock(block.id)}
          deleteBlock={@deleteBlock.bind(this, block.id)}
          moveBlock={@props.moveBlock}
        />
    blocks.sort (a, b) ->
      a.props.block.order - b.props.block.order

    if @props.editable
      addBlock = <li className="row view-all">
                    <div>
                      <div className='button large' onClick={@addBlock}>Add New Block</div>
                    </div>
                  </li>
      deleteWeek = <span className="button danger" onClick={@props.deleteWeek}>Delete Week</span>
    if @props.showTitle == undefined || @props.showTitle
      title = <p>
                <span>Week {@props.index}&nbsp;&nbsp;&mdash;&nbsp;&nbsp;</span>
                <TextInput
                  onChange={@updateWeek}
                  value={@props.week.title}
                  value_key={'title'}
                  editable={@props.editable}
                />
                {deleteWeek}
              </p>

    <li className="week">
      {title}
      <ul className="list">
        {blocks}
        {addBlock}
      </ul>
    </li>
)

module.exports = Week