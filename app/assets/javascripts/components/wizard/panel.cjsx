React       = require 'react/addons'
CourseLink  = require '../common/course_link'

Option      = require './option'

Panel = React.createClass(
  displayName: 'Panel'
  advance: (answer_key) ->
    @props.advance(@props.key, @state.selected)
  rewind: ->
    @props.rewind()
  selectOption: (answer_key) ->
    selected = []
    if @props.type == 1 || @props.type == undefined
      selected = [answer_key]
    else
      selected = $.extend([], @state.selected)
      if answer_key in @state.selected
        selected.splice(selected.indexOf(answer_key), 1)
      else
        selected.push(answer_key)
    @setState selected: selected
  getInitialState: ->
    selected: []
  render: ->
    options = @props.options.map (option, i) =>
      <Option {...option}
        key={i}
        selected={(option.key || i) in @state.selected}
        selectOption={@selectOption.bind(this, option.key || i)}
      />
    classes = 'wizard__panel'
    classes += ' active' if @props.active
    button_text = if @props.last then 'Submit' else 'Next'
    inst = if @props.type == 0 then 'Select one or more' else 'Select one'
    step = if @props.step == 0 then '' else 'Step ' + @props.step + ' of ' + @props.steps
    if @props.steps? && @props.steps > 1
      rewind = <div className="button" onClick={@rewind}>Previous</div>

    <div className={classes}>
      {@props.wizard_controls}
      <h3>{@props.title}</h3>
      <p>{@props.description}</p>
      <p>{inst}</p>
      {options}
      <div className='wizard__panel__controls'>
        <div className='left'>
          <p>{step}</p>
        </div>
        <div className='right'>
          {rewind}
          <div className="button dark" onClick={@advance}>{button_text}</div>
        </div>
      </div>
    </div>
)

module.exports = Panel
