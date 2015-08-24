McFly           = require 'mcfly'
Flux            = new McFly()

ServerActions   = require '../actions/server_actions'

_active_index = 0
_summary = false
_wizard_key = null
_panels = [{
  title:  I18n.t('wizard.course_dates')
  description: ''
  active: true
  options: []
  type: -1
  minimum: 0
  key: 'dates'
},{
  title:  I18n.t('wizard.assignment_dates')
  description: I18n.t('wizard.assignment_description')
  active: false
  options: []
  type: -1
  minimum: 0
  key: 'timeline'
},{
  title: I18n.t('wizard.assignment_type')
  description: I18n.t('wizard.select_assignment')
  active: false
  options: []
  type: 1
  minimum: 1
  key: 'index'
},{
  title: I18n.t('wizard.summary')
  description: I18n.t('wizard.review_selections')
  active: false
  options: []
  type: -1
  minimum: 0
  key: 'summary'
}]

# Utilities
setIndex = (index) ->
  # index of the assignment panel
  _panels[2].options = index
  WizardStore.emitChange()

setPanels = (panels) ->
  # 4 hard-coded panels: course dates, timeline dates, assignments, summary
  # _panels.length will change when more are inserted
  to_remove = _panels.length - 4
  # insert retrieved panels after hardcoded panels, but before summary
  # also remove if you chose a different assignment but went back
  # 3 (for now) is index of the first to remove (the first retrieved panel)
  _panels.splice.apply(_panels, [3, to_remove].concat(panels))
  moveWizard() if _active_index > 0
  WizardStore.emitChange()

updateActivePanels = ->
  if _panels.length > 0
    _panels.forEach (panel) -> panel.active = false
    _panels[_active_index].active = true

selectOption = (panel_index, option_index, value=true) ->
  panel = _panels[panel_index]
  option = panel.options[option_index]
  unless panel.type == 0  # multiple choice
    panel.options.forEach (option) -> option.selected = false
  option.selected = !(option.selected || false)
  verifyPanelSelections(panel)
  _summary = _summary && !(_active_index == 1 && _summary)
  WizardStore.emitChange()

expandOption = (panel_index, option_index) ->
  panel = _panels[panel_index]
  option = panel.options[option_index]
  option.expanded = !(option.expanded || false)
  WizardStore.emitChange()

moveWizard = (backwards=false, to_index=null) ->
  active_panel = _panels[_active_index]
  increment = if backwards then -1 else 0

  if !backwards && verifyPanelSelections(active_panel)
    increment = 1
    if _active_index == 2 # assignment step
      selected_wizard = _.find(_panels[_active_index].options, (o) -> o.selected)
      if selected_wizard.key != _wizard_key
        _wizard_key = selected_wizard.key
        ServerActions.fetchWizardPanels(selected_wizard.key)
        increment = 0

  if to_index?
    _active_index = to_index
  else
    _active_index += increment

  _summary = to_index? if backwards

  if _active_index == -1
    _active_index = 0
  else if _active_index == _panels.length || (_summary && !backwards)
    _active_index = _panels.length - 1

  #####
  # THIS IS CHECK TO SEE IF WE NEED TO SCROLL PANEL TO TOP BEFORE TRANSITION
  # THERE IS PERHAPS A BETTER PLACE THEN THIS FILE TO PUT THIS EVENT/TRANSITION
  #####
  timeoutTime = if increment != 0 then 150 else 0
  if timeoutTime > 0
    if $('.wizard').scrollTop() > 0
      $('.wizard').animate(
        scrollTop: 0
      ,timeoutTime)

  setTimeout(->
    updateActivePanels()
    WizardStore.emitChange()
  ,timeoutTime)

verifyPanelSelections = (panel) ->
  return true if panel.options == undefined || panel.options.length == 0
  selection_count = panel.options.reduce (selected, option) ->
    selected += if option.selected then 1 else 0
  , 0
  verified = selection_count >= panel.minimum
  if verified
    panel.error = null
  else
    error_message = I18n.t('wizard.minimum_options', { minimum: panel.minimum })
    panel.error = error_message
  return verified

restore = ->
  _summary = false
  _active_index = 0
  updateActivePanels()
  _wizard_key = null
  setPanels([])
  _panels[0].options.forEach (option) -> option.selected = false
  WizardStore.emitChange()

# Store
WizardStore = Flux.createStore
  getPanels: ->
    $.extend([], _panels, true)
  getWizardKey: ->
    _wizard_key
  getSummary: ->
    _summary
  getAnswers: ->
    answers = []
    _panels.forEach (panel, i) ->
      return if i == _panels.length - 1
      answer = { title: panel.title, selections: [] }
      if panel.options != undefined && panel.options.length > 0
        panel.options.map (option) ->
          answer.selections.push option.title if option.selected
        answer.selections = ['No selections'] if answer.selections.length == 0
      answers.push answer
    answers
  getOutput: ->
    output = []
    logic = []
    tags = []
    _panels.forEach (panel) ->
      if $.isArray(panel.output)
        output = output.concat panel.output
      else
        output.push panel.output
      if panel.options != undefined && panel.options.length > 0
        panel.options.forEach (option) ->
          return unless option.selected
          if option.output?
            if $.isArray(option.output)
              output = output.concat option.output
            else
              output.push option.output
          logic.push option.logic if option.logic?
          tags.push { key: panel.key, tag: option.tag } if option.tag?
    { output: output, logic: logic, tags: tags }

, (payload) ->
  data = payload.data
  switch(payload.actionType)
    when 'RECEIVE_WIZARD_INDEX'
      setIndex data.wizard_index
      break
    when 'RECEIVE_WIZARD_PANELS'
      setPanels data.wizard_panels
      break
    when 'SELECT_OPTION'
      selectOption data.panel_index, data.option_index
      break
    when 'EXPAND_OPTION'
      expandOption data.panel_index, data.option_index
      break
    when 'WIZARD_ADVANCE'
      moveWizard()
      break
    when 'WIZARD_REWIND'
      moveWizard true, data.to_index
      break
    when 'WIZARD_RESET', 'WIZARD_SUBMITTED'
      restore()
      break
  return true

module.exports = WizardStore
