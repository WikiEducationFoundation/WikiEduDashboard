require('jquery-ui/sortable');
require('jquery.repeater');

SurveyAdmin =
  init: ->
    @$question_type_select = $('#question_type')
    @$question_form_options = $('[data-question-options]')
    @$question_text_input = $('[data-question-text]')
    @$question_text_editor = $('[data-question-text-editor]')
    @initSortableQuestions()
    @initSortableQuestionGroups()
    @initRepeaters()
    @listeners()

  listeners: ->
    @handleQuestionType()
    @$question_type_select.on 'change', $.proxy(@, 'handleQuestionType')

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
        console.log item_id
        position = ui.item.index()
        $.ajax
          type: 'POST'
          url: "/surveys/question_groups/#{question_group_id}/questions/update_position"
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



module.exports = SurveyAdmin