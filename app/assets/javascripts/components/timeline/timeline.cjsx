React           = require 'react'

RDnD            = require 'react-dnd'
Touch           = require('react-dnd-touch-backend').default
DDContext       = RDnD.DragDropContext

Week            = require './week.cjsx'
EmptyWeek       = require('./empty_week.jsx').default
Loading         = require('../common/loading.jsx').default
CourseLink      = require('../common/course_link.jsx').default
Affix           = require('../common/affix.jsx').default

WeekActions     = require('../../actions/week_actions.js').default
BlockActions    = require('../../actions/block_actions.js').default

BlockStore      = require '../../stores/block_store.coffee'
WeekStore       = require '../../stores/week_store.coffee'

DateCalculator  = require('../../utils/date_calculator.js').default
CourseUtils     = require('../../utils/course_utils.js').default

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
    if confirm I18n.t('timeline.delete_week_confirmation')
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

  tooManyWeeks: ->
    nonEmptyWeeks = @props.week_meetings.filter (week) -> week != '()'
    nonEmptyWeeks.length < @props.weeks.length

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

    if @tooManyWeeks()
      tooManyWeeksWarning =
        <li className="timeline-warning">
          WARNING! There are not enough non-holiday weeks before the assignment end date!
        </li>

    # For each week, first insert an extra empty week for each week with empty
    # week meetings, which indicates a blackout week. Then insert the week itself.
    # The index 'i' represents the zero-index week number; both empty and non-empty
    # weeks are included in this numbering scheme.
    @props.weeks.forEach (week, weekIndex) =>
      while @props.week_meetings[i] == '()'
        week_components.push (
          <div key={"empty-week-#{i}"}>
            <a className="timeline__anchor" name={"week-#{i + 1}"} />
            <EmptyWeek
              course={@props.course}
              edit_permissions={@props.edit_permissions}
              index={i + 1}
              timeline_start={@props.course.timeline_start}
              timeline_end={@props.course.timeline_end}
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
            meetings={@props.week_meetings[i]}
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

    # If there are no weeks at all, put in a special placeholder week with the
    # emptyTimeline parameter
    if !@props.loading && @props.weeks.length is 0
      no_weeks = (
        <EmptyWeek
          course={@props.course}
          index={1}
          emptyTimeline
          timeline_start={@props.course.timeline_start}
          timeline_end={@props.course.timeline_end}
          edit_permissions={@props.edit_permissions}
        />
      )

    unless week_components.length > 0
      wizard_link = <CourseLink to="/courses/#{@props.course?.slug}/timeline/wizard" className='button dark button--block timeline__add-assignment'>Add Assignment</CourseLink>

    controls = if @props.reorderable || @props?.editable_block_ids.length > 1 then (
      <div>
        <button className="button dark button--block" onClick={@props.saveGlobalChanges}>
          {I18n.t('timeline.save_all_changes')}
        </button>
        <button className="button button--clear button--block" onClick={@props.cancelGlobalChanges}>
          {I18n.t('timeline.discard_all_changes')}
        </button>
      </div>
    )

    if @props.edit_permissions
      if @props.reorderable
        reorderable_controls = (
          <div className="reorderable-controls">
            <h5>{I18n.t('timeline.arrange_timeline')}</h5>
            <p className="muted">{I18n.t('timeline.arrange_timeline_instructions')}</p>
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
          <label className='week-nav__action week-nav__link disabled tooltip-trigger'>
            {I18n.t('timeline.add_week')}
            <div className="tooltip dark">
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
        <a href={"#week-#{i + 1}"}>{week.title || I18n.t('timeline.week_number', number: i + 1)}</a>
        <span className="pull-right">{dateCalc.start()} - {dateCalc.end()}</span>
      </li>
    )

    sidebar = if @props.course.id then (
      <div className="timeline__week-nav">
        <Affix offset={100}>
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
    ) else (
      <div className="timeline__week-nav">
      </div>
    )


    <div>
      <div className="timeline__content">
        <ul className="list-unstyled timeline__weeks">
          {tooManyWeeksWarning}
          {week_components}
          {no_weeks}
        </ul>
        {sidebar}
      </div>
    </div>
)

module.exports = DDContext(Touch({ enableMouseEvents: true }))(Timeline)
