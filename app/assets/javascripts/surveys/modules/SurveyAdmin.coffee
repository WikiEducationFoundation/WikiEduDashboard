require('jquery-ui/sortable');

SurveyAdmin =
  init: ->
    @$question_type_select = $('#question_type')
    @$question_form_options = $('[data-question-options]')
    @$question_text_input = $('[data-question-text]')
    @$question_text_editor = $('[data-question-text-editor]')
    @initSortable()
    @listeners()

  listeners: ->
    @handleQuestionType()
    @$question_type_select.on 'change', $.proxy(@, 'handleQuestionType')

  initSortable: ->
    $sortable = $('[data-sortable]')
    question_group_id = $sortable.data 'sortable'
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


module.exports = SurveyAdmin