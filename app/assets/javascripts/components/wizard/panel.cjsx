React       = require 'react/addons'
CourseLink  = require '../common/course_link'

Option      = require './option'

Panel = React.createClass(
  displayName: 'Panel'
  advance: ->
    answer_key = 0
    @props.advance(@props.key, answer_key)
  render: ->
    options = @props.options.map (option, i) ->
      <Option {...option} key={i + Date.now()} />
    classes = 'wizard__panel'
    classes += ' active' if @props.active
    <div className={classes}>
      <h1>{@props.title}</h1>
      <p>{@props.description}</p>
      {options}
      <CourseLink to='timeline' className='button large'>Cancel</CourseLink>
      <div className="button dark large" onClick={@advance}>Next</div>
    </div>
)

module.exports = Panel
