React         = require 'react/addons'
WizardActions = require '../../actions/wizard_actions'
WizardStore   = require '../../stores/wizard_store'

CourseLink    = require '../common/course_link'
Option        = require './option'

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
      rewind =  <div className="button" onClick={@rewind}>{'Previous'}</div>

    options = @props.raw_options || @props.panel.options.map (option, i) =>
      <Option option={option}
        panel_index={@props.index}
        key={@props.index + '' + i}
        index={i}
        multiple={@props.panel.type == 0}
      />

    classes = 'wizard__panel'
    classes += ' active' if @props.panel.active
    advance = @props.advance || @advance

    <div className={classes}>
      <div className='wizard__controls'>
        <p>
          <CourseLink to='timeline'>Back to dashboard</CourseLink>
          <a href='' onClick={@reset}>Start over</a>
        </p>
      </div>
      <h3>{@props.panel.title}</h3>
      <p>{@props.panel.description}</p>
      <div className='wizard__panel__options'>{options}</div>
      <div className='wizard__panel__controls'>
        <div className='left'>
          <p>{@props.step}</p>
        </div>
        <div className='right'>
          <div><p className='red'>{@props.panel.error}</p></div>
          {rewind}
          <div className="button dark" onClick={advance}>{@props.button_text || 'Next'}</div>
        </div>
      </div>
    </div>
)

module.exports = Panel