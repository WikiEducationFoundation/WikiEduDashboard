
require('jquery-ui/sortable');
require('jquery.repeater');
Utils = require './SurveyUtils.coffee'
CONDITIONAL_ANSWERS_CHANGED = 'ConditionalAnswersChanged'

SurveyAdmin =
  init: ->
    @$document = $(document)
    @$question_type_select = $('#question_type')
    @$question_form_options = $('[data-question-options]')
    @$question_text_input = $('[data-question-text]')
    @$question_text_editor = $('[data-question-text-editor]')
    @$conditional_operator = $('[data-conditional-operator]')
    @$conditional_operator_select = $('[data-conditional-operator-select]')
    @$add_conditional_button = $('[data-add-conditional]')
    @$clear_conditional_button = $('[data-clear-conditional]')
    @$conditional_question_select = $('[data-conditional-select]')
    @$conditional_value_select = $('[data-conditional-value-select]')
    @$conditional_input_field = $('[data-conditional-field-input]')
    @$conditional_value_number_field = $('[data-conditional-value-number]')
    @initSortableQuestions()
    @initSortableQuestionGroups()
    @initRepeaters()
    @listeners()
    @initConditionals()

  listeners: ->
    @handleQuestionType()
    @$clear_conditional_button.on 'click', $.proxy(@, 'clearConditional')
    @$conditional_question_select.on 'change', $.proxy(@, 'handleConditionalSelect')
    @$conditional_value_select.on 'change', $.proxy(@, 'handleConditionalAnswerSelect')
    @$question_type_select.on 'change', $.proxy(@, 'handleQuestionType')
    @$add_conditional_button.on 'click', $.proxy(@, 'addConditional')

  initSortableQuestions: ->
    $sortable = $('[data-sortable-questions]')
    question_group_id = $sortable.data 'sortable-questions'
    $sortable.sortable
      axis: 'y'
      items: '.row--survey-question'
      # containment: 'parent'
      scroll: false
      cursor: 'move'
      sort: (e, ui) ->
        ui.item.addClass 'active-item-shadow'
      stop: (e, ui) ->
        ui.item.removeClass 'active-item-shadow'
      update: (e, ui) ->
        item_id = ui.item.data 'item-id'
        position = ui.item.index()
        $.ajax
          type: 'PUT'
          url: "/surveys/question_position"
          dataType: 'json'
          data: { question_group_id: question_group_id, id: item_id, position: position }

  initSortableQuestionGroups: ->
    $sortable = $('[data-sortable-question-groups]')
    survey_id = $sortable.data 'sortable-question-groups'
    $sortable.sortable
      axis: 'y'
      items: '.question-group-row'
      scroll: false
      cursor: 'move'
      sort: (e, ui) ->
        ui.item.addClass 'active-item-shadow'
      stop: (e, ui) ->
        ui.item.removeClass 'active-item-shadow'
      update: (e, ui) ->
        item_id = ui.item.data 'item-id'
        console.log item_id
        position = ui.item.index()
        $.ajax
          type: 'POST'
          url: "/surveys/update_question_group_position"
          dataType: 'json'
          data: { survey_id: survey_id, question_group_id: item_id, position: position }

  handleQuestionType: ->
    return unless @$question_type_select.length
    switch @$question_type_select.val().split('::').pop()
      when 'Text'
        @setQuestionTextEditor()
      else
        @resetQuestionText()

  setQuestionTextEditor: ->
    if @question_html_backup?
      @$question_text_input.val @question_html_backup
    @$question_text_input.addClass 'hidden'
    @$question_form_options.addClass 'hidden'
    @$question_text_editor.html "<trix-editor input='question_text'></trix-editor>"
  
  resetQuestionText: ->
    @question_html_backup = @$question_text_input.val()
    @$question_text_input.val @question_html_backup.replace(/(<([^>]+)>)/ig,"").replace('&nbsp;', ' ')
    @$question_text_input.removeClass 'hidden'
    @$question_form_options.removeClass 'hidden'
    @$question_text_editor.empty()

  initRepeaters: ->
    $('[data-repeater]').repeater
      defaultValues: 'text-input': 'foo'
      show: ->
        $(this).slideDown()
        return
      hide: (deleteElement) ->
        if confirm('Are you sure you want to delete this element?')
          $(this).slideUp deleteElement
        return
      ready: (setIndexes) ->
        # $dragAndDrop.on 'drop', setIndexes
        return
      isFirstItemUndeletable: true

  handleConditionalSelect: (e) ->
    id = e.target.value
    if id isnt ""
      @conditional = {}
      @conditional.question_id = id
      @getQuestion(id)

  getQuestion: (id) ->
    $.ajax
      url: "/surveys/question_group_question/#{id}"
      method: 'get'
      dataType: 'json'
      contentType: 'application/json'
      success: $.proxy @, 'handleConditionalQuestionSelect'
      error: (e) -> console.log 'error', e

  handleConditionalQuestionSelect: (e) ->
    console.log e.question_type
    @clearConditionalOperatorAndValue()
    switch e.question_type
      when 'long', 'short'
        @textConditional(e.question)
      when 'rangeinput'
        @comparisonConditional(e.question)
      else
        @multipleChoiceConditional e.question

  textConditional: (question) ->
    console.log 'TEXT CONDITIONAL', question
    @$conditional_operator.text 'is present'
    @addPresenceConditional()

  comparisonConditional: (question) ->
    console.log 'COMPARISON CONDITIONAL', question
    @$conditional_operator_select.append("<option>></option><option><</option>").removeClass 'hidden'
    @$conditional_value_number_field.removeClass 'hidden'
    @$conditional_value_number_field.on 'blur', (e) =>
      conditional_string = ""
      conditional_string += "#{@$conditional_question_select.val()}|"
      conditional_string += "#{@$conditional_operator_select.val()}|"
      conditional_string += e.target.value
      console.log conditional_string
      @$conditional_input_field.val conditional_string

  multipleChoiceConditional: (question)->
    @$conditional_operator.text "="
    @conditional.operator = "="
    @$clear_conditional_button.removeClass 'hidden'
    answers = question.answer_options.split('\n')
    @$conditional_value_select.append "<option value='nil' slelected>Select an Answer</option>"
    answers.map (answer, i) =>
      answer_value = answer.trim()
      @$conditional_value_select.append "<option value='#{answer_value}'>#{answer_value}</option>"
    @$conditional_value_select.removeClass 'hidden'
    @$document.trigger CONDITIONAL_ANSWERS_CHANGED

  handleConditionalAnswerSelect: ({target}) ->
    if target.value isnt 'nil'
      @conditional.answer_value =  target.value
      @addMultiConditional()

  initConditionals: ->
    $('[data-conditional]').each (i, conditional_row) =>
      $row = $(conditional_row)
      string = $row.data 'conditional'
      return if string is ''
      { question_id, operator, value } = Utils.parseConditionalString string
      $row.find('select').val("#{question_id}").trigger 'change'
      @$conditional_operator.text operator
      @$document.on CONDITIONAL_ANSWERS_CHANGED, =>
        @$conditional_value_select.val(value).trigger 'change'
        @$document.off CONDITIONAL_ANSWERS_CHANGED

  addPresenceConditional: ->
    @$conditional_input_field.val "#{@$conditional_question_select.val()}|*presence"

  addMultiConditional: (e) ->
    e.preventDefault() if e?
    conditional_string = ""
    conditional_string += "#{@$conditional_question_select.val()}|"
    conditional_string += "#{@$conditional_operator.text()}|"
    conditional_string += "#{@$conditional_value_select.val()}|multi"
    @$conditional_input_field.val conditional_string

  addComparisonConditional: (e) ->
    # 
  
  clearConditional: (e) ->
    e.preventDefault() if e?
    @$conditional_operator.text ''
    @$conditional_question_select.prop 'selectedIndex', 0
    @clearConditionalOperatorAndValue()
    @$conditional_input_field.val null

  clearConditionalOperatorAndValue: ->
    @$conditional_value_select.addClass('hidden').prop 'selectedIndex', 0
    @$clear_conditional_button.addClass 'hidden'
    @$conditional_value_number_field.val('').addClass 'hidden'
    @$conditional_operator_select.off('blur').empty().addClass 'hidden'


module.exports = SurveyAdmin