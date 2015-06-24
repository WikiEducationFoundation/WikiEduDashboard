React           = require 'react/addons'
Marked          = require 'marked'
MarkedRenderer  = require '../../utils/marked_renderer'
WizardActions   = require '../../actions/wizard_actions'
WizardStore     = require '../../stores/wizard_store'

CourseLink      = require '../common/course_link'
Option          = require './option'

Panel = React.createClass(
  displayName: 'Panel'
  advance: ->
    WizardActions.advanceWizard()
  rewind: ->
    WizardActions.rewindWizard()
  reset: (e) ->
    e.preventDefault()
    WizardActions.resetWizard()
  render: ->
    if @props.index > 0
      rewind =  <button onClick={@rewind}>{'Previous'}</button>

    options_1 = []
    options_2 = []
    if @props.panel.options != undefined
      @props.panel.options.forEach (option, i) =>
        option = (
          <Option option={option}
            panel_index={@props.index}
            key={@props.index + '' + i}
            index={i}
            multiple={@props.panel.type == 0}
          />
        )
        if i % 2 == 0 then options_1.push(option) else options_2.push(option)

    options = @props.raw_options || (
      <div>
        <div className="left">{options_1}</div>
        <div className="right">{options_2}</div>
      </div>
    )
    classes = 'wizard__panel'
    classes += ' active' if @props.panel.active
    advance = @props.advance || @advance

    next_text = @props.button_text || (if @props.summary then 'Summary' else null) || 'Next'

    <div className={classes}>
      <div className='wizard__controls'>
        <p>
          <CourseLink to='timeline' className='icon icon-left_arrow'>Back to dashboard</CourseLink>
          <a href='' onClick={@reset} className='icon icon-restart'>Start over</a>
        </p>
      </div>
      <h3>{@props.panel.title}</h3>
      <div dangerouslySetInnerHTML={{__html: Marked(@props.panel.description, { renderer: MarkedRenderer })}}></div>
      <div className='wizard__panel__options'>{options}</div>
      <div className='wizard__panel__controls'>
        <div className='left'>
          <p>{@props.step}</p>
        </div>
        <div className='right'>
          <div><p className='red'>{@props.panel.error}</p></div>
          {rewind}
          <button className="dark" onClick={advance}>{next_text}</button>
        </div>
      </div>
    </div>
)

module.exports = Panel