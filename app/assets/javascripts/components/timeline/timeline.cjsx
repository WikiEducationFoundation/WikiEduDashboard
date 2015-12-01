React           = require 'react'

RDnD            = require 'react-dnd'
HTML5Backend    = require 'react-dnd-html5-backend'
DDContext       = RDnD.DragDropContext

Week            = require './week'
Loading         = require '../common/loading'
CourseLink      = require '../common/course_link'
Affix           = require '../common/affix'

Waypoint        = require 'react-waypoint'

WeekActions     = require '../../actions/week_actions'
BlockActions    = require '../../actions/block_actions'

BlockStore      = require '../../stores/block_store'

Timeline = React.createClass(
  displayName: 'Timeline'
  getInitialState: ->
    week_entered: 0
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

  _setScrolled: ->
    @setState unscrolled: false

  _handleWaypointEnter: (week_id) ->
    @setState week_entered: week_id

  componentDidMount: ->
    window.addEventListener 'scroll', @_setScrolled

  componentDidUnMount: ->
    window.removeEventListener 'scroll'

  render: ->
    week_components = []

    unless @props.weeks.length > 0
      return <Loading />

    @props.weeks.map (week, i) =>
      unless week.deleted
        if @props.course.week_meetings?
          while @props.course.week_meetings[i] == '()'
            week_components.push (
              <Week
                blocks={[]}
                week={title: null}
                index={i + 1}
                key={"noweek_#{i}"}
                start_date={week.start_date}
                end_date={week.end_date}
                editable=false
                meetings='(No meetings this week)'
                all_training_modules={@props.all_training_modules}
              />
            )

        week_components.push (
          <div key={week.id}>
            <a className="timeline__anchor" name={"week-#{week.id}"} />
            <Week
              week={week}
              index={i + 1}
              editable={@props.editable}
              blocks={BlockStore.getBlocksInWeek(week.id)}
              moveBlock={@moveBlock}
              deleteWeek={@deleteWeek.bind(this, week.id)}
              meetings={if @props.course.week_meetings? then @props.course.week_meetings[i] else ''}
              all_training_modules={@props.all_training_modules}
            />
            <Waypoint onEnter={@_handleWaypointEnter.bind(@, week.id)} />
          </div>
        )

    if @props.editable
      add_week_button = if @props.course.timeline_full then (
        <div className='button dark disabled' title='You cannot add new weeks when your timeline is full. Delete at least one week to make room for a new one.'>Add New Week</div>
      ) else (
        <button className='button dark' onClick={@addWeek}>Add New Week</button>
      )
      add_week = (
        <li className="row view-all">
          <div>{add_week_button}</div>
          <br />
          <div>
            {@props.controls(null, false, true)}
          </div>
        </li>
      )
    unless week_components.length
      no_weeks = (
        <li className="row view-all">
          <div><p>This course does not have a timeline yet</p></div>
        </li>
      )

    unless week_components.length > 0
      wizard_link = <CourseLink to="/courses/#{@props.course.slug}/timeline/wizard" className='button dark'>Add Assignment</CourseLink>

    controls = (
      <span>
        {wizard_link}
        <CourseLink to="/courses/#{@props.course.slug}/timeline/dates" className='button dark'>Edit Course Dates</CourseLink>
      </span>
    )

    week_nav = @props.weeks.map (week, i) => (
      className = ''
      if @state.unscrolled is true && i == 0
        className += 'is-current '
      if @state.unscrolled is false && @state.week_entered is week.id
        className += 'is-current '
      <li className={className} key={"week-#{week.id}"}>
        <a href={"#week-#{week.id}"}>{week.title || "Week #{i + 1}"}</a>
        <span className="pull-right">{week.start_date} - {week.end_date}</span>
      </li>
    )

    <div>
      <div className="section-header">
        <h3>Timeline</h3>
        <div className="timeline-ctas">
          {@props.controls(controls)}
        </div>
      </div>
      <div className="timeline__content">
        <ul className="list-unstyled timeline__weeks">
          {week_components}
          {no_weeks}
          {add_week}
        </ul>
        <div className="timeline__week-nav">
          <Affix offset={220}>
            <ol>
              {week_nav}
            </ol>
          </Affix>
        </div>
      </div>
    </div>
)

module.exports = DDContext(HTML5Backend)(Timeline)
