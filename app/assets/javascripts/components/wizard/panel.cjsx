React           = require 'react'
md              = require('markdown-it')({ html: true, linkify: true })
WizardActions   = require '../../actions/wizard_actions'
WizardStore     = require '../../stores/wizard_store'

CourseLink      = require '../common/course_link'
Option          = require './option'

Panel = React.createClass(
  displayName: 'Panel'
  advance: ->
    WizardActions.advanceWizard()
  rewind: (e) ->
    e.preventDefault()
    WizardActions.rewindWizard()
  reset: (e) ->
    e.preventDefault()
    WizardActions.resetWizard()
  close: (e) ->
    confirm "This will close the wizard without saving your progress. Are you sure you want to do this?"
  nextEnabled: ->
    !@props.hasOwnProperty('nextEnabled') || (@props.hasOwnProperty('nextEnabled') && @props.nextEnabled() is true)
  render: ->
    if @props.index > 0
      rewind =  <button className='button' onClick={@rewind}>{'Previous'}</button>
      rewind_top = <a href='' onClick={@rewind} className='icon icon-left_arrow'>Previous</a>

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
            open_weeks={@props.open_weeks}
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

    next_text = @props.button_text || (if @props.summary then 'Summary' else 'Next')


    reqs_met = _.reduce(@props.panel.options, (total, option) ->
      total + (if option.selected then 1 else 0)
    , 0) >= @props.panel.minimum
    reqs_met = reqs_met || !(@props.panel.options? && @props.panel.minimum)

    if @props.panel.minimum? && @props.panel.minimum > 0
      reqs = I18n.t('wizard.minimum_options', { minimum: @props.panel.minimum })

    helper_text = @props.helperText || ""

    <div className={classes}>
      <div className='wizard__controls'>
        <div className='left'>
          {rewind_top}
        </div>
        <div className='right'>
          <CourseLink to="/courses/#{@props.course.slug}/timeline" onClick={@close}>Close</CourseLink>
        </div>
      </div>
      <h3>{@props.panel.title}</h3>
      <div dangerouslySetInnerHTML={{__html: md.render(@props.panel.description)}}></div>
      <div className='wizard__panel__options'>{options}</div>
      <div className='wizard__panel__controls'>
        <div className='left'>
          <p>{@props.step}</p>
        </div>
        <div className='right'>
          <div><p className={if @props.panel.error? then 'red' else ''}>{@props.panel.error || reqs}</p></div>
          {rewind}
          <div><p>{helper_text}</p></div>
          <button className="button dark" onClick={advance} disabled={if reqs_met && @nextEnabled() then '' else 'disabled'}>{next_text}</button>
        </div>
      </div>
    </div>
)

module.exports = Panel
