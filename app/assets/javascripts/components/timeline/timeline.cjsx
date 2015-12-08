React           = require 'react'

RDnD            = require 'react-dnd'
HTML5Backend    = require 'react-dnd-html5-backend'
DDContext       = RDnD.DragDropContext

Week            = require './week'
Loading         = require '../common/loading'
CourseLink      = require '../common/course_link'
Affix           = require '../common/affix'

WeekActions     = require '../../actions/week_actions'
BlockActions    = require '../../actions/block_actions'

BlockStore      = require '../../stores/block_store'

Timeline = React.createClass(
  displayName: 'Timeline'

  propTypes:
    loading: React.PropTypes.bool
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
    WeekActions.deleteWeek(week_id)
  moveBlock: (block_id, after_block_id) ->
    return if block_id == after_block_id
    block = BlockStore.getBlock block_id
    after_block = BlockStore.getBlock after_block_id
    if block.week_id == after_block.week_id   # dragging within a week
      old_order = block.order
      block.order = after_block.order
      after_block.order = old_order
      BlockActions.updateBlock block, true
      BlockActions.updateBlock after_block
    else
      block.week_id = after_block.week_id
      BlockActions.insertBlock block, after_block.week_id, after_block.order

  _scrolledToBottom: ->
    scrollTop = (document.documentElement && document.documentElement.scrollTop) || document.body.scrollTop
    scrollHeight = (document.documentElement && document.documentElement.scrollHeight) || document.body.scrollHeight
    (scrollTop + window.innerHeight) >= scrollHeight

  _handleScroll: ->
    @setState unscrolled: false
    scrollTop = window.scrollTop || document.body.scrollTop
    bodyTop = document.body.getBoundingClientRect().top
    weekEls = document.getElementsByClassName('week')
    navItems = document.getElementsByClassName('week-nav__item')
    Array.prototype.forEach.call weekEls, (el, i) =>
      elTop = el.getBoundingClientRect().top - bodyTop
      headerHeight = 90
      if scrollTop >= elTop - headerHeight
        Array.prototype.forEach.call navItems, (item) =>
          item.classList.remove('is-current')
        if !@_scrolledToBottom()
          navItems[i]?.classList.add('is-current')
        else
          navItems[navItems.length - 1]?.classList.add('is-current')

  componentDidMount: ->
    window.addEventListener 'scroll', @_handleScroll

  componentDidUnMount: ->
    window.removeEventListener 'scroll'

  render: ->
    week_components = []


    unless @props.course? || @props.weeks.length > 0
      return <Loading />

    @props.weeks.map (week, i) =>
      unless week.deleted
        if @props?.week_meetings
          while @props?.week_meetings[i] == '()'
            week_components.push (
              <Week
                blocks={[]}
                week={title: null}
                index={i + 1}
                key={"noweek_#{i}"}
                editable=false
                meetings=false
                all_training_modules={@props.all_training_modules}
              />
            )
            i++

        isEditable = @props.editable_week_id == week.id
        week_components.push (
          <div key={week.id}>
            <a className="timeline__anchor" name={"week-#{week.id}"} />
            <Week
              week={week}
              index={i + 1}
              editable={isEditable}
              blocks={BlockStore.getBlocksInWeek(week.id)}
              moveBlock={@moveBlock}
              deleteWeek={@deleteWeek.bind(this, week.id)}
              meetings={if @props?.week_meetings then @props.week_meetings[i] else ''}
              all_training_modules={@props.all_training_modules}
              editable_block_ids={@props.editable_block_ids}
              saveBlockChanges={@props.saveBlockChanges}
              cancelBlockEditable={@props.cancelBlockEditable}
              saveGlobalChanges={@props.saveGlobalChanges}
            />
          </div>
        )

    add_week_button = if @props.course?.timeline_full then (
      <span className='week-nav__action week-nav__link disabled' title='You cannot add new weeks when your timeline is full. Delete at least one week to make room for a new one.'>Add New Week</span>
    ) else (
      <span className='week-nav__action week-nav__link' onClick={@addWeek}>Add New Week</span>
    )

    unless week_components.length
      no_weeks = (
        <li className="row view-all">
          <div><p>This course does not have a timeline yet</p></div>
        </li>
      )

    unless week_components.length > 0
      wizard_link = <CourseLink to="/courses/#{@props.course?.slug}/timeline/wizard" className='button dark'>Add Assignment</CourseLink>

    controls = if @props?.editable && @props?.editable_block_ids.length > 1 then (
      <div>
        <span>
          {wizard_link}
        </span>
        <button className="button dark pull-right" onClick={@props.saveGloablChanges}>
          Save All
        </button>
        <button className="pull-right timeline-ctas__cancel" onClick={@props.cancelGlobalChanges}>
          Discard All Changes
        </button>
      </div>
    )
    else (
        <span>
          {wizard_link}
        </span>
    )


    week_nav = @props.weeks.map (week, i) => (
      className = 'week-nav__item'
      className += ' is-current' if i == 0
      <li className={className} key={"week-#{week.id}"}>
        <a href={"#week-#{week.id}"}>{week.title || "Week #{i + 1}"}</a>
        <span className="pull-right">{week.start_date} - {week.end_date}</span>
      </li>
    )

    <div>
      <div className="timeline__content">
        <ul className="list-unstyled timeline__weeks">
          {week_components}
          {no_weeks}
        </ul>
        <div className="timeline__week-nav">
          <section className="timeline-ctas float-container">
            {controls}
          </section>
          <Affix offset={220}>
            <ol>
              {week_nav}
            </ol>
            <CourseLink className="week-nav__action week-nav__link" to="/courses/#{@props.course?.slug}/timeline/dates">Edit Course Dates</CourseLink>
            {add_week_button}
          </Affix>
        </div>
      </div>
    </div>
)

module.exports = DDContext(HTML5Backend)(Timeline)
