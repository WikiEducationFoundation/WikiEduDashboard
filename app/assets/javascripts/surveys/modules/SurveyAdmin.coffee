markdown = require('../../utils/markdown_it.js').default()
require('jquery-ui/sortable')
require('jquery-ui/tabs')
autosize = require('autosize')
striptags = require('striptags')
Utils = require './SurveyUtils.coffee'
CONDITIONAL_ANSWERS_CHANGED = 'ConditionalAnswersChanged'
CONDITIONAL_COMPARISON_OPERATORS = """
  <option>></option>
  <option>>=</option>
  <option><</option>
  <option><=</option>
"""

SurveyAdmin =
  init: ->
    $('[data-tabs]').tabs();
    autosize($('textarea'));
    @cacheSelectors()
    @course_data = @$course_data_populate_checkbox.attr('checked')?
    @initSortableQuestions()
    @initSortableQuestionGroups()
    @listeners()
    @initConditionals()
    @initSearchableList()
    @initMarkdown()
    $('[data-chosen-select]').chosen({disable_search_threshold: 10});

  listeners: ->
    @handleQuestionType()
    @$clear_conditional_button.on 'click', $.proxy(@, 'clearConditional')
    @$conditional_question_select.on 'change', $.proxy(@, 'handleConditionalSelect')
    @$conditional_value_select.on 'change', $.proxy(@, 'handleConditionalAnswerSelect')
    @$question_type_select.on 'change', $.proxy(@, 'handleQuestionType')
    @$add_conditional_button.on 'click', $.proxy(@, 'addConditional')
    @$course_data_populate_checkbox.on 'change', $.proxy @, 'handleCourseDataCheckboxChange'
    @$follow_up_question_checkbox.on 'change', $.proxy @, 'handleFollowUpCheckboxChange'
    @$matrix_options_checkbox.on 'change', $.proxy @, 'handleMatrixCheckboxChange'
    @$conditional_option_checkbox.on 'change', $.proxy @, 'handleConditionalCheckboxChange'

  cacheSelectors: ->
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
    @$question_type_options = $('[data-question-type-options]')
    @$question_type_options_hide_if = $('[question-type-options-hide-if]')
    @$question_type_fields = $('[data-question-type-field]')
    @$course_data_populate_checkbox = $('[data-course-data-populate-checkbox]')
    @$follow_up_question_checkbox = $('[data-follow-up-question-checkbox]')
    @$conditional_option_checkbox = $('[data-conditional-option-checkbox]')
    @$matrix_options_checkbox = $('[data-matrix-checkbox]')
    @$course_data_type_select = $('#question_course_data_type')
    @$answer_options = $('[data-answer-options]')
    @$range_input_options = $('[data-question-type-options="RangeInput"')

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
        position = ui.item.index() + 1 #acts_as_list defaults to start at 1
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
        position = ui.item.index() + 1 #acts_as_list defaults to start at 1
        $.ajax
          type: 'POST'
          url: "/surveys/update_question_group_position"
          dataType: 'json'
          data: { survey_id: survey_id, question_group_id: item_id, position: position }

  handleQuestionType: ->
    return unless @$question_type_select.length
    type = @$question_type_select.val().split('::').pop()
    @$question_type_options.addClass 'hidden'
    switch type
      when 'Text'
        @setQuestionTextEditor()
        @clearRangeInputOptions()
      when 'RangeInput'
        @hideQuestionTypes 'RangeInput'
        @showQuestionTypes 'RangeInput'
        @resetQuestionText()
      else
        @hideQuestionTypes type
        @showQuestionTypes type
        @resetQuestionText()
        @clearRangeInputOptions()

  hideQuestionTypes: (string) ->
    $("[data-question-type-options-hide-if*='#{string}']").addClass 'hidden'

  showQuestionTypes: (string) ->
    $("[data-question-type-options*='#{string}']").removeClass 'hidden'
    @$answer_options.addClass 'hidden' if @course_data

    switch string
      when 'Select', 'Checkbox', 'Radio'
        @$answer_options.removeClass 'hidden' if !@course_data
      when 'Long', 'Short'
        @$answer_options.addClass 'hidden'

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

  handleConditionalSelect: (e) ->
    id = e.target.value
    if id isnt ""
      @conditional = {}
      @conditional.question_id = id
      @getQuestion(id)

  clearRangeInputOptions: ->
    @$range_input_options.find('input').val ''

  getQuestion: (id) ->
    $.ajax
      url: "/surveys/question_group_question/#{id}"
      method: 'get'
      dataType: 'json'
      contentType: 'application/json'
      success: $.proxy @, 'handleConditionalQuestionSelect'


  handleConditionalQuestionSelect: (e) ->
    @clearConditionalOperatorAndValue()
    switch e.question_type
      when 'long', 'short'
        @textConditional(e.question)
      when 'rangeinput'
        @comparisonConditional(e.question)
      else
        @multipleChoiceConditional e.question

  handleCourseDataCheckboxChange: ({target}) ->
    $course_data = $('[data-question-type-field="course_data"]')
    if target.checked
      @course_data = true
      $course_data.removeClass 'hidden'
      @$answer_options.addClass 'hidden'
    else
      @course_data = false
      @$course_data_type_select.prop 'selectedIndex', 0
      $course_data.addClass 'hidden'
      @$answer_options.removeClass 'hidden'

  handleFollowUpCheckboxChange: ({target}) ->
    $option = $('[data-question-type-field="follow_up_question"]')
    if target.checked
      $option.removeClass 'hidden'
    else
      $option.addClass 'hidden'

  handleMatrixCheckboxChange: ({target}) ->
    $option = $('[data-question-type-field="matrix"]')
    if target.checked
      $option.removeClass 'hidden'
    else
      $option.addClass 'hidden'

  handleConditionalCheckboxChange: ({target}) ->
    $option = $('[data-conditional-options]')
    if target.checked
      $option.removeClass 'hidden'
    else
      $option.addClass 'hidden'

  textConditional: (question) ->
    @$conditional_operator.text 'is present'
    @addPresenceConditional()

  comparisonConditional: (question) ->
    @$conditional_operator_select.append(CONDITIONAL_COMPARISON_OPERATORS).removeClass 'hidden'
    @$conditional_value_number_field.removeClass 'hidden'
    @$conditional_value_number_field.on 'blur', (e) =>
      conditional_string = ""
      conditional_string += "#{@$conditional_question_select.val()}|"
      conditional_string += "#{@$conditional_operator_select.val()}|"
      conditional_string += e.target.value
      @$conditional_input_field.val conditional_string

  multipleChoiceConditional: (question)->
    @$conditional_operator.text "="
    @conditional.operator = "="
    @$clear_conditional_button.removeClass 'hidden'
    answers = question.answer_options.split('\n')
    @$conditional_value_select.append "<option value='nil' slelected>Select an Answer</option>"
    answers.map (answer, i) =>
      answer_value = answer.trim()
      @$conditional_value_select.append "<option value='#{@sanitizeAnswerValue(answer_value)}'>#{answer_value}</option>"
    @$conditional_value_select.removeClass 'hidden'
    @$document.trigger CONDITIONAL_ANSWERS_CHANGED

  sanitizeAnswerValue: (string) ->
    striptags(string).replace('\'', '&#39;').replace('\"', '&#34;').split(' ').join('_')
    # string.replace('\'', '&#39;').replace('\"', '&#34;')


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
      switch operator
        when ">", "<=", ">", ">="
          $row.find('select').val("#{question_id}")
          @$conditional_operator_select.append(CONDITIONAL_COMPARISON_OPERATORS).removeClass 'hidden'
          @$conditional_operator_select.val(operator).trigger('change').removeClass 'hidden'
          @$conditional_value_number_field.val(value).removeClass 'hidden'
        else
          @$conditional_operator.text operator
          @$document.on CONDITIONAL_ANSWERS_CHANGED, =>
            @$conditional_value_select.val(value).trigger 'change'
            @$document.off CONDITIONAL_ANSWERS_CHANGED
          $row.find('select').val("#{question_id}").trigger 'change'

  addPresenceConditional: ->
    @$conditional_input_field.val "#{@$conditional_question_select.val()}|*presence"

  addMultiConditional: (e) ->
    e.preventDefault() if e?
    conditional_string = ""
    conditional_string += "#{@$conditional_question_select.val()}|"
    conditional_string += "#{@$conditional_operator.text()}|"
    conditional_string += "#{@$conditional_value_select.val()}|multi"
    @$conditional_input_field.val conditional_string

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

  initSearchableList: ->
    fuzzyOptions =
      searchClass: 'fuzzy-search'
      location: 0
      distance: 100
      threshold: 0.4
      multiSearch: true

    options =
      valueNames: ['name', 'status', 'author']
      plugins: [
        ListFuzzySearch()
      ]

    listObj = new List('searchable-list', options)

  initMarkdown: ->
    updateMarkdownTabs = (source, $preview, $source) ->
      console.log(source, $preview, $source)
      $preview.html source
      $source.text source

    $('[data-markdown-source]').each (i, text) ->
      $text = $(text)
      id = $text.data('markdown-source')
      $preview = $("[data-markdown-preview='#{id}']")
      $source = $("[data-markdown-source-view='#{id}']")
      update = ->
        html = markdown.render $text.val()
        updateMarkdownTabs html, $preview, $source
      update()
      $text.keyup update

    $('[data-render-markdown-label]').each (i, text) ->
      $text = $(text)
      $target = $text.next('[data-markdown-target]')
      $target.html markdown.render $text.data 'render-markdown-label'



module.exports = SurveyAdmin
