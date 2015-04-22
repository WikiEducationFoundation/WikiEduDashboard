React           = require 'react'
TimelineStore   = require './timeline_store'
TimelineActions = require './timeline_actions'
Week            = require './week'

getState = (slug) ->
  weeks: TimelineStore.getTimeline(slug)

Timeline = React.createClass(
  mixins: [TimelineStore.mixin]
  contextTypes:
    router: React.PropTypes.func.isRequired
  getInitialState: ->
    getState(this.getSlug())
  storeDidChange: ->
    this.setState(getState(this.getSlug()))
  addWeek: ->
    TimelineActions.addWeek(this.getSlug(), { title: 'Newest Week' })
  deleteWeek: (week_id) ->
    TimelineActions.deleteWeek(week_id)
  getSlug: ->
    params = this.context.router.getCurrentParams()
    params.course_school + '/' + params.course_title
  render: ->
    weeks = this.state.weeks.map (week, i) =>
      <Week {...week}
        courseSlug={this.getSlug()}
        index={i}
        key={week.id}
        deleteWeek={this.deleteWeek.bind(this, week.id)}
      />

    <ul className="list">
      {weeks}
      <li className="row view-all">
        <div>
          <a onClick={this.addWeek}>Add New Week</a>
        </div>
      </li>
    </ul>
)

module.exports = Timeline