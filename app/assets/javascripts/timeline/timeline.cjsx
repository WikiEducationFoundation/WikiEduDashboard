React = require 'react'
Store = require './store'
Actions = require './actions'

getState = (slug) ->
  weeks: Store.getTimeline(slug)

Timeline = React.createClass(
  mixins: [Store.mixin]
  contextTypes:
    router: React.PropTypes.func.isRequired
  getInitialState: ->
    params = this.context.router.getCurrentParams()
    slug = params.course_school + '/' + params.course_title
    getState(slug)
  storeDidChange: ->
    console.log 'getting state'
    params = this.context.router.getCurrentParams()
    slug = params.course_school + '/' + params.course_title
    this.setState(getState(slug))
  addWeek: ->
    console.log 'ADD A WEEK'
  render: ->
    weeks = this.state.weeks.map (week, i) ->
      <Week {...week} index={i} />

    <ul className="list">
      {weeks}
      <li className="row view-all">
        <div onClick={this.addWeek}><p>Add New Week</p></div>
      </li>
    </ul>
)

module.exports = Timeline

Week = React.createClass(
  addBlock: ->
    console.log 'ADD A BLOCK TO ' + this.props.title
  render: ->
    <li className="week row">
      <ul className="list">
        <li className="row view-all">
          <p>Week {this.props.index} - {this.props.title}</p>
          <div onClick={this.addBlock}><p>Add New Block</p></div>
        </li>
      </ul>
    </li>
)