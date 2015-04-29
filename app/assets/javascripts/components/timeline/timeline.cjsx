React           = require 'react'
TimelineStore   = require '../../stores/timeline_store'
TimelineActions = require '../../actions/timeline_actions'
Week            = require './week'
EditableInterface = require '../common/editable_interface.jsx'

getState = (slug) ->
  weeks: TimelineStore.getTimeline(slug)

Timeline = React.createClass(
  displayName: 'Timeline'
  addWeek: ->
    TimelineActions.addWeek()
  deleteWeek: (week_id) ->
    TimelineActions.deleteWeek(week_id)
  render: ->
    weeks = this.props.weeks.map (week, i) =>
      unless week.deleted
        <Week {...week}
          index={i}
          key={week.id}
          editable={this.props.editable}
          deleteWeek={this.deleteWeek.bind(this, week.id)}
        />
    if this.props.editable
      addWeek = <li className="row view-all">
                  <div>
                    <a onClick={this.addWeek}>Add New Week</a>
                  </div>
                </li>

    <ul className="list">
      <li className="row view-all">{this.props.controls}</li>
      {weeks}
      {addWeek}
    </ul>
)

module.exports = EditableInterface(Timeline, TimelineStore, getState, TimelineActions)