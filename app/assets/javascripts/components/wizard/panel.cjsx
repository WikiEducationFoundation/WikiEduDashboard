React       = require 'react/addons'
CourseLink  = require '../common/course_link'

Option      = require './option'

Panel = React.createClass(
  displayName: 'Panel'
  advance: (answer_key) ->
    @props.advance(@props.key, @state.selected)
  selectOption: (answer_key) ->
    @setState selected: answer_key
  getInitialState: ->
    selected: null
  render: ->
    options = @props.options.map (option, i) =>
      <Option {...option}
        key={i}
        selected={@state.selected == (option.key || i)}
        selectOption={@selectOption.bind(this, option.key || i)}
      />
    classes = 'wizard__panel'
    classes += ' active' if @props.active
    button_text = if @props.last then 'Submit' else 'Next'
    <div className={classes}>
      <h1>{@props.title}</h1>
      <p>{@props.description}</p>
      {options}
      <CourseLink to='timeline' className='button large'>Cancel</CourseLink>
      <div className="button dark large" onClick={@advance}>{button_text}</div>
    </div>
)

module.exports = Panel
