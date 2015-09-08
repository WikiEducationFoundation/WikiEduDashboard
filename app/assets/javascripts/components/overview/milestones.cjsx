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
      milestone_blocks = _.select(week.blocks, (block) => block.kind == @milestoneBlockType)
      milestone_blocks.map (block) =>
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
    @emptyMessage = if !@blocks.length then I18n.t('blocks.milestones.empty') else ''

    <div className='module milestones'>
      <div className="section-header">
        <h3>{I18n.t('blocks.milestones.title')}</h3>
      </div>
      <p>{@emptyMessage}</p>
      {@blocks}
    </div>
)

module.exports = Milestones

