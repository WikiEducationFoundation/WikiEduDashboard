React          = require 'react'
BlockStore     = require '../../stores/block_store.coffee'
WeekStore      = require '../../stores/week_store.coffee'
CourseStore    = require '../../stores/course_store.coffee'
md             = require('markdown-it')({ html: true, linkify: true })
CourseUtils   = require '../../utils/course_utils.coffee'

getState = ->
  weeks: WeekStore.getWeeks()
  currentWeek: CourseStore.getCurrentWeek()

Milestones = React.createClass(
  displayName: I18n.t('blocks.milestones.title')
  mixins: [BlockStore.mixin, WeekStore.mixin, CourseStore.mixin]
  storeDidChange: ->
    @setState getState()
  getInitialState: ->
    getState()
  milestoneBlockType: 2
  weekIsCompleted: (week) ->
    week.order < @state.currentWeek
  render: ->
    blocks = []
    weeks = @state.weeks.map (week) =>
      milestone_blocks = _.select(week.blocks, (block) => block.kind == @milestoneBlockType)
      milestone_blocks.map (block) =>
        classNames = 'module__data'
        classNames += ' completed' if @weekIsCompleted(week)
        raw_html = md.render(block.content)
        blocks.push(
          <div key={block.id} className='section-header'>
            <div className={classNames}>
              <p>Week {week.order} {if @weekIsCompleted(week) then '- Complete'}</p>
              <div className='markdown' dangerouslySetInnerHTML={{__html: raw_html}}></div>
              <hr />
            </div>
          </div>
        )

    if !blocks.length
      return null

    <div className='module milestones'>
      <div className="section-header">
        <h3>{I18n.t('blocks.milestones.title')}</h3>
      </div>
      {blocks}
    </div>
)

module.exports = Milestones
