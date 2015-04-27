React           = require 'react'
TimelineStore   = require '../stores/timeline_store'
TimelineActions = require '../actions/timeline_actions'
Week            = require './week'
Checkbox        = require './checkbox'

getState = (slug) ->
  weeks: TimelineStore.getTimeline(slug)

Timeline = React.createClass(
  displayName: 'Timeline'
  mixins: [TimelineStore.mixin]
  contextTypes:
    router: React.PropTypes.func.isRequired
  getInitialState: ->
    new_state = getState(this.getSlug())
    new_state.editable = if this.state then this.state.editable else false
    new_state
  storeDidChange: ->
    this.setState(getState(this.getSlug()))
  addWeek: ->
    TimelineActions.addWeek(this.getSlug(), { title: 'Newest Week' })
  deleteWeek: (week_id) ->
    TimelineActions.deleteWeek(week_id)
  getSlug: ->
    params = this.context.router.getCurrentParams()
    params.course_school + '/' + params.course_title
  toggleEditable: ->
    this.setState
      editable: !this.state.editable
  saveChanges: ->
    console.log 'save changes!!'
    this.toggleEditable()
  render: ->
    weeks = this.state.weeks.map (week, i) =>
      <Week {...week}
        courseSlug={this.getSlug()}
        index={i}
        key={week.id}
        editable={this.state.editable}
        deleteWeek={this.deleteWeek.bind(this, week.id)}
      />
    if this.state.editable
      addWeek = <li className="row view-all">
                  <div>
                    <a onClick={this.addWeek}>Add New Week</a>
                  </div>
                </li>
      controls = <p>
                    <button
                      value={'cancel'}
                      onClick={this.toggleEditable}
                    >Cancel</button>
                    <button
                      value={'save'}
                      onClick={this.saveChanges}
                    >Save</button>
                 </p>
    else
      controls =  <p>
                    <button
                      value={'edit'}
                      onClick={this.toggleEditable}
                    >Edit</button>
                  </p>

    <ul className="list">
      <li className="row view-all">{controls}</li>
      {weeks}
      {addWeek}
    </ul>
)

module.exports = Timeline