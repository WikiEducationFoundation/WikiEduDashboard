React           = require 'react'

RDnD            = require 'react-dnd'
Touch           = require('react-dnd-touch-backend').default
DDContext       = RDnD.DragDropContext

Week            = require './week.cjsx'
Loading         = require '../common/loading.cjsx'
CourseLink      = require '../common/course_link.cjsx'
Affix           = require '../common/affix.cjsx'

WeekActions     = require '../../actions/week_actions.coffee'
BlockActions    = require '../../actions/block_actions.coffee'

BlockStore      = require '../../stores/block_store.coffee'
WeekStore       = require '../../stores/week_store.coffee'

DateCalculator  = require '../../utils/date_calculator.coffee'
CourseUtils     = require '../../utils/course_utils.coffee'

Timeline = React.createClass(
  displayName: 'Timeline'

  propTypes:
    loading: React.PropTypes.bool
    course: React.PropTypes.object.isRequired
    weeks: React.PropTypes.array
    week_meetings: React.PropTypes.array
    editable_block_ids: React.PropTypes.array
    editable: React.PropTypes.bool
    controls: React.PropTypes.func
    saveGlobalChanges: React.PropTypes.func
    cancelGlobalChanges: React.PropTypes.func
    saveBlockChanges: React.PropTypes.func
    cancelBlockEditable: React.PropTypes.func
    all_training_modules: React.PropTypes.array

  getInitialState: ->
    unscrolled: true
  addWeek: ->
    WeekActions.addWeek()
  deleteWeek: (week_id) ->
    if confirm "Are you sure you want to delete this week? This will delete the week and all its associated blocks.\n\nThis cannot be undone."
      WeekActions.deleteWeek(week_id)

  _handleBlockDrag: (targetIndex, block, target) ->
    originalIndexCheck = BlockStore.getBlocksInWeek(block.week_id).indexOf(block)
    if originalIndexCheck != targetIndex || block.week_id != target.week_id
      toWeek = WeekStore.getWeek(target.week_id)
      @_moveBlock(block, toWeek, targetIndex)

  _moveBlock: (block, toWeek, afterBlock) ->
    BlockActions.insertBlock block, toWeek, afterBlock

  _handleMoveBlock: (moveUp, block_id) ->
    for week, i in @props.weeks
      blocks = BlockStore.getBlocksInWeek(week.id)
      for block, j in blocks
        if block_id == block.id
          if moveUp && j == 0 || !moveUp && j == blocks.length - 1
            # Move to adjacent week
            toWeek = @props.weeks[if moveUp then i - 1 else i + 1]
            if moveUp
              toWeekBlocks = BlockStore.getBlocksInWeek(toWeek.id)
              atIndex = toWeekBlocks.length - 1
            @_moveBlock(block, toWeek, atIndex)
          else
            # Swap places with the adjacent block
            atIndex = if moveUp then j - 1 else j + 1
            @_moveBlock(block, week, atIndex)
          return

  _canBlockMoveDown: (week, weekIndexInTimeline, block, blockIndexInWeek) ->
    return false if weekIndexInTimeline == @props.weeks.length - 1 && blockIndexInWeek == BlockStore.getBlocksInWeek(week.id).length - 1
    # TODO: return false if it's the last block in the last non-blackout week
    return true

  _canBlockMoveUp: (week, weekIndexInTimeline, block, blockIndexInWeek) ->
    return false if weekIndexInTimeline == 0 && blockIndexInWeek == 0
    # TODO: return false if it's the first block in the first non-blackout week
    return true

  _scrolledToBottom: ->
    scrollTop = (document.documentElement && document.documentElement.scrollTop) || document.body.scrollTop
    scrollHeight = (document.documentElement && document.documentElement.scrollHeight) || document.body.scrollHeight
    (scrollTop + window.innerHeight) >= scrollHeight

  _handleScroll: _.throttle ->
    @setState unscrolled: false
    scrollTop = window.scrollTop || document.body.scrollTop || window.pageYOffset
    bodyTop = document.body.getBoundingClientRect().top
    weekEls = document.getElementsByClassName('week')
    navItems = document.getElementsByClassName('week-nav__item')
    Array.prototype.forEach.call weekEls, (el, i) =>
      elTop = el.getBoundingClientRect().top - bodyTop
      topOffset = 90
      if scrollTop >= elTop - topOffset
        Array.prototype.forEach.call navItems, (item) =>
          item.classList.remove('is-current')
        if !@_scrolledToBottom()
          navItems[i]?.classList.add('is-current')
        else
          navItems[navItems.length - 1]?.classList.add('is-current')
  , 150

  componentDidMount: ->
    window.addEventListener 'scroll', @_handleScroll

  componentWillUnmount: ->
    window.removeEventListener 'scroll', @_handleScroll

  render: ->
    if @props.loading
      return <Loading />

    week_components = []
    i = 0

    @props.weeks.sort (a, b) ->
      a.order - b.order

    @props.weeks.forEach (w) ->
      w.blocks.sort (a, b) ->
        a.order - b.order

    @props.weeks.forEach (week, weekIndex) =>
      unless week.deleted
        if @props?.week_meetings
          while @props?.week_meetings[i] == '()'
            week_components.push (
              <div key={"empty-week-#{i}"}>
                <a className="timeline__anchor" name={"week-#{i + 1}"} />
                <Week
                  blocks={[]}
                  week={title: null}
                  index={i + 1}
                  key={"noweek_#{i}"}
                  timeline_start={@props.course.timeline_start}
                  timeline_end={@props.course.timeline_end}
                  editable=false
                  meetings=false
                  all_training_modules={@props.all_training_modules}
                />
              </div>
            )
            i++

        isEditable = @props.editable_week_id == week.id
        week_components.push (
          <div key={week.id}>
            <a className="timeline__anchor" name={"week-#{i + 1}"} />
            <Week
              week={week}
              index={i + 1}
              editable={isEditable}
              reorderable={@props.reorderable}
              blocks={BlockStore.getBlocksInWeek(week.id)}
              deleteWeek={@deleteWeek.bind(this, week.id)}
              meetings={if @props?.week_meetings then @props.week_meetings[i] else ''}
              timeline_start={@props.course.timeline_start}
              timeline_end={@props.course.timeline_end}
              all_training_modules={@props.all_training_modules}
              editable_block_ids={@props.editable_block_ids}
              edit_permissions={@props.edit_permissions}
              saveBlockChanges={@props.saveBlockChanges}
              cancelBlockEditable={@props.cancelBlockEditable}
              saveGlobalChanges={@props.saveGlobalChanges}
              canBlockMoveUp={@_canBlockMoveUp.bind(this, week, weekIndex)}
              canBlockMoveDown={@_canBlockMoveDown.bind(this, week, weekIndex)}
              onMoveBlockUp={@_handleMoveBlock.bind(this, true)}
              onMoveBlockDown={@_handleMoveBlock.bind(this, false)}
              onBlockDrag={@_handleBlockDrag}
            />
          </div>
        )
        i++


    if !@props.loading && @props.weeks.length is 0
      no_weeks = (
        <Week
          course={@props.course}
          index={1}
          week={{is_new: false}}
          blocks=[]
          empty_timeline=true
          timeline_start={@props.course.timeline_start}
          timeline_end={moment(@props.course.timeline_start).add(6, 'day')}
          edit_permissions={@props.edit_permissions}
        />
      )

    unless week_components.length > 0
      wizard_link = <CourseLink to="/courses/#{@props.course?.slug}/timeline/wizard" className='button dark button--block timeline__add-assignment'>Add Assignment</CourseLink>

    controls = if @props.reorderable || @props?.editable_block_ids.length > 1 then (
      <div>
        <button className="button dark button--block" onClick={@props.saveGlobalChanges}>
          Save All
        </button>
        <button className="button button--clear button--block" onClick={@props.cancelGlobalChanges}>
          Discard All Changes
        </button>
      </div>
    )

    if @props.edit_permissions
      if @props.reorderable
        reorderable_controls = (
          <div className="reorderable-controls">
            <h5>Arrange Timeline</h5>
            <p className="muted">Arrange timeline by ‘dragging & dropping’ blocks into the desired location/week, or reposition the blocks using the arrows on the card.</p>
          </div>
        )
      else if @props.editable_block_ids.length == 0
        reorderable_controls = (
          <div className="reorderable-controls">
            <button className="button border button--block" onClick={@props.enableReorderable}>Arrange Timeline</button>
          </div>
        )

      edit_course_dates = (
        <CourseLink className="week-nav__action week-nav__link" to="/courses/#{@props.course?.slug}/timeline/dates">{CourseUtils.i18n('edit_course_dates', @props.course.string_prefix)}</CourseLink>
      )

      start = moment(@props.course.timeline_start)
      end = moment(@props.course.timeline_end)
      timeline_full = (moment(end - start).weeks()) - week_components.length <= 0
      add_week_link = if timeline_full then (
        <li>
          <label className='week-nav__action week-nav__link disabled popover-trigger'>
            Add Week
            <div className="popover dark">
              <p>{I18n.t('timeline.unable_to_add_week')}</p>
            </div>
          </label>
        </li>
      ) else (
        <li>
          <span className="week-nav__add-week" onClick={@addWeek}>Add Week</span>
        </li>
      )

    week_nav = week_components.map (week, i) => (
      className = 'week-nav__item'
      className += ' is-current' if i == 0

      dateCalc = new DateCalculator(@props.course.timeline_start, @props.course.timeline_end, i, zeroIndexed: true)
      <li className={className} key={"week-#{i}"}>
        <a href={"#week-#{i + 1}"}>{week.title || "Week #{i + 1}"}</a>
        <span className="pull-right">{dateCalc.start()} - {dateCalc.end()}</span>
      </li>
    )


    <div>
      <div className="timeline__content">
        <ul className="list-unstyled timeline__weeks">
          {week_components}
          {no_weeks}
        </ul>
        <div className="timeline__week-nav">
          <Affix offset={246}>
            <section className="timeline-ctas float-container">
              <span>{wizard_link}</span>
              {reorderable_controls}
              {controls}
            </section>
            <div className="panel">
              <ol>
                {week_nav}
                {add_week_link}
              </ol>
              {edit_course_dates}
              <a className="week-nav__action week-nav__link" href="#grading">Grading</a>
            </div>
          </Affix>
        </div>
      </div>
    </div>
)

module.exports = DDContext(Touch({ enableMouseEvents: true }))(Timeline)
