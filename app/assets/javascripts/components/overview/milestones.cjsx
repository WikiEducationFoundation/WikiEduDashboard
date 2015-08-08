React          = require 'react'
BlockStore     = require '../../stores/block_store'
WeekStore      = require '../../stores/week_store'
CourseStore    = require '../../stores/course_store'
Marked         = require 'marked'
MarkedRenderer = require '../../utils/marked_renderer'

getState = ->
  weeks: WeekStore.getWeeks()
  currentWeek: CourseStore.getCurrentWeek()

Milestones = React.createClass(
  displayName: 'Milestones'
  mixins: [BlockStore.mixin, WeekStore.mixin, CourseStore.mixin]
  storeDidChange: ->
    @setState getState()
  getInitialState: ->
    getState()
  blocks: []
  milestoneBlockType: 2
  weekIsCompleted: (week) ->
    week.order < @state.currentWeek
  render: ->
    weeks = @state.weeks.map (week) =>
      week.blocks.map (block) =>
        if block.kind == @milestoneBlockType
          classNames = 'module__data'
          classNames += ' completed' if @weekIsCompleted(week)
          raw_html = Marked(block.content, { renderer: MarkedRenderer })
          @blocks.push(
            <div key={block.id} className='section-header'>
              <div className={classNames}>
                <p>Week {week.order} {if @weekIsCompleted(week) then '- Complete'}</p>
                <div className='markdown' dangerouslySetInnerHTML={{__html: raw_html}}></div>
                <hr />
              </div>
            </div>
          )

    <div className='module milestones'>
      <h3>{I18n.t('blocks.milestones')}</h3>
      {@blocks}
    </div>
)

module.exports = Milestones

