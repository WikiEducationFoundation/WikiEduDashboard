React           = require 'react/addons'
DND             = require 'react-dnd'
HTML5DND        = require 'react-dnd/modules/backends/HTML5'
Block           = require './block'
BlockActions    = require '../../actions/block_actions'
WeekActions     = require '../../actions/week_actions'
GradeableStore  = require '../../stores/gradeable_store'
TextInput       = require '../common/text_input'

ReactCSSTG      = React.addons.CSSTransitionGroup

Week = React.createClass(
  displayName: 'Week'
  getInitialState: ->
    focusedBlockId: null
  addBlock: ->
    BlockActions.addBlock @props.week.id
  deleteBlock: (block_id) ->
    BlockActions.deleteBlock block_id
  updateWeek: (value_key, value) ->
    to_pass = $.extend(true, {}, @props.week)
    to_pass['title'] = value
    WeekActions.updateWeek to_pass
  toggleFocused: (block_id) ->
    if @state.focusedBlockId == block_id
      @setState focusedBlockId: null
    else
      @setState focusedBlockId: block_id
  render: ->
    # Start and end dates
    start = moment(@props.start).startOf('week').add(7 * (@props.index - 1), 'day')
    end = moment.min(start.clone().add(6, 'day'), moment(@props.end))

    blocks = @props.blocks.map (block, i) =>
      unless block.deleted
        <Block
          toggleFocused={@toggleFocused.bind(this, block.id)}
          canDrag={@state.focusedBlockId != block.id}
          block={block}
          key={block.id}
          editable={@props.editable}
          gradeable={GradeableStore.getGradeableByBlock(block.id)}
          deleteBlock={@deleteBlock.bind(this, block.id)}
          moveBlock={@props.moveBlock}
          week_index={@props.index}
          week_start={moment(@props.start).startOf('isoWeek').add(7 * (@props.index - 1), 'day')}
          all_training_modules={@props.all_training_modules}
        />
    blocks.sort (a, b) ->
      a.props.block.order - b.props.block.order

    if @props.editable
      addBlock = (
        <li className="row view-all">
          <div>
            <button className='button' onClick={@addBlock}>Add New Block</button>
          </div>
        </li>
      )
      deleteWeek = <button onClick={@props.deleteWeek} className='button danger right'>Delete Week</button>
    if @props.showTitle == undefined || @props.showTitle
      if (@props.week.title? || @props.editable)
        spacer = '  —  '
      else
        spacer = ' '
      week_label = 'Week ' + @props.index
      # Final label
      week_label += " (#{start.format('MM/DD')} - #{end.format('MM/DD')}) #{@props.meetings}"
      title = (
        <TextInput
          onChange={@updateWeek}
          value={@props.week.title}
          value_key={'title'}
          editable={@props.editable}
          label={week_label}
          spacer={spacer}
          placeholder='Title'
        />
      )

    weekClassName = "week week-#{@props.index}"
    <li className={weekClassName}>
      <div style={overflow: 'hidden'}>
        {deleteWeek}
        {title}
      </div>
      <ul className="list-unstyled">
        {blocks}
        {addBlock}
      </ul>
    </li>
)

module.exports = Week
