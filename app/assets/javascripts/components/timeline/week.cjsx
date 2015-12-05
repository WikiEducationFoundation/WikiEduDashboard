React           = require 'react'
DND             = require 'react-dnd'
HTML5DND        = require 'react-dnd-html5-backend'
Block           = require './block'
BlockActions    = require '../../actions/block_actions'
WeekActions     = require '../../actions/week_actions'
GradeableStore  = require '../../stores/gradeable_store'
TextInput       = require '../common/text_input'

ReactCSSTG      = require 'react-addons-css-transition-group'

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
          week_start={@props.start_date}
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
      week_label = 'Week ' + @props.index
      title = (
        <TextInput
          onChange={@updateWeek}
          value={@props.week.title}
          value_key={'title'}
          editable={@props.editable}
          label={week_label}
          spacer=' '
          placeholder='Title'
        />
      )

      week_dates = (
        <span className='week__week-dates pull-right'>
          {@props.week.start_date} - {@props.week.end_date} {@props.meetings if @props.meetings}
        </span>
      )

    week_content = if @props.meetings then (
      <ul className="week__block-list list-unstyled">
        {blocks}
        {addBlock}
      </ul>
    ) else (
      <div className="week__no-activity">
        <h1 className="h3">No activity this week</h1>
      </div>
    )

    weekClassName = "week week-#{@props.index}"
    <li className={weekClassName}>
      <div className="week__week-header">
        {deleteWeek}
        {week_dates}
        {title}
      </div>
      {week_content}
    </li>
)

module.exports = Week
