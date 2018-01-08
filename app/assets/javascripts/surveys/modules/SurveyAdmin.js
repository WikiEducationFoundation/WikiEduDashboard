import 'jquery-ui/ui/widgets/sortable';
import 'jquery-ui/ui/widgets/tabs';
import autosize from 'autosize';
import striptags from 'striptags';
import Utils from './SurveyUtils.js';
require('chosen-js');

const markdown = require('../../utils/markdown_it.js').default();
const CONDITIONAL_ANSWERS_CHANGED = 'ConditionalAnswersChanged';
const CONDITIONAL_COMPARISON_OPERATORS = `\
<option>></option>
<option>>=</option>
<option><</option>
<option><=</option>\
`;

const SurveyAdmin = {
  init() {
    $('[data-tabs]').tabs();
    autosize($('textarea'));
    this.cacheSelectors();
    this.course_data = Boolean(this.$course_data_populate_checkbox.attr('checked'));
    this.initSortableQuestions();
    this.initSortableQuestionGroups();
    this.listeners();
    this.initConditionals();
    this.initSearchableList();
    this.initMarkdown();
    return $('[data-chosen-select]').chosen({ disable_search_threshold: 10 });
  },

  listeners() {
    this.handleQuestionType();
    this.$clear_conditional_button.on('click', $.proxy(this, 'clearConditional'));
    this.$conditional_question_select.on('change', $.proxy(this, 'handleConditionalSelect'));
    this.$conditional_value_select.on('change', $.proxy(this, 'handleConditionalAnswerSelect'));
    this.$question_type_select.on('change', $.proxy(this, 'handleQuestionType'));
    this.$add_conditional_button.on('click', $.proxy(this, 'addConditional'));
    this.$course_data_populate_checkbox.on('change', $.proxy(this, 'handleCourseDataCheckboxChange'));
    this.$follow_up_question_checkbox.on('change', $.proxy(this, 'handleFollowUpCheckboxChange'));
    this.$matrix_options_checkbox.on('change', $.proxy(this, 'handleMatrixCheckboxChange'));
    return this.$conditional_option_checkbox.on('change', $.proxy(this, 'handleConditionalCheckboxChange'));
  },

  cacheSelectors() {
    this.$document = $(document);
    this.$question_type_select = $('#question_type');
    this.$question_form_options = $('[data-question-options]');
    this.$question_text_input = $('[data-question-text]');
    this.$question_text_editor = $('[data-question-text-editor]');
    this.$conditional_operator = $('[data-conditional-operator]');
    this.$conditional_operator_select = $('[data-conditional-operator-select]');
    this.$add_conditional_button = $('[data-add-conditional]');
    this.$clear_conditional_button = $('[data-clear-conditional]');
    this.$conditional_question_select = $('[data-conditional-select]');
    this.$conditional_value_select = $('[data-conditional-value-select]');
    this.$conditional_input_field = $('[data-conditional-field-input]');
    this.$conditional_value_number_field = $('[data-conditional-value-number]');
    this.$question_type_options = $('[data-question-type-options]');
    this.$question_type_options_hide_if = $('[question-type-options-hide-if]');
    this.$question_type_fields = $('[data-question-type-field]');
    this.$course_data_populate_checkbox = $('[data-course-data-populate-checkbox]');
    this.$follow_up_question_checkbox = $('[data-follow-up-question-checkbox]');
    this.$conditional_option_checkbox = $('[data-conditional-option-checkbox]');
    this.$matrix_options_checkbox = $('[data-matrix-checkbox]');
    this.$course_data_type_select = $('#question_course_data_type');
    this.$answer_options = $('[data-answer-options]');
    return this.$range_input_options = $('[data-question-type-options="RangeInput"');
  },

  initSortableQuestions() {
    const $sortable = $('[data-sortable-questions]');
    const questionGroupId = $sortable.data('sortable-questions');
    return $sortable.sortable({
      axis: 'y',
      items: '.row--survey-question',
      // containment: 'parent'
      scroll: false,
      cursor: 'move',
      sort(e, ui) {
        return ui.item.addClass('active-item-shadow');
      },
      stop(e, ui) {
        return ui.item.removeClass('active-item-shadow');
      },
      update(e, ui) {
        const itemId = ui.item.data('item-id');
        const position = ui.item.index() + 1; // acts_as_list defaults to start at 1
        return $.ajax({
          type: 'PUT',
          url: '/surveys/question_position',
          dataType: 'json',
          data: { question_group_id: questionGroupId, id: itemId, position }
        });
      }
    });
  },

  initSortableQuestionGroups() {
    const $sortable = $('[data-sortable-question-groups]');
    const surveyId = $sortable.data('sortable-question-groups');
    return $sortable.sortable({
      axis: 'y',
      items: '.question-group-row',
      scroll: false,
      cursor: 'move',
      sort(e, ui) {
        return ui.item.addClass('active-item-shadow');
      },
      stop(e, ui) {
        return ui.item.removeClass('active-item-shadow');
      },
      update(e, ui) {
        const itemId = ui.item.data('item-id');
        const position = ui.item.index() + 1; // acts_as_list defaults to start at 1
        return $.ajax({
          type: 'POST',
          url: '/surveys/update_question_group_position',
          dataType: 'json',
          data: { survey_id: surveyId, question_group_id: itemId, position }
        });
      }
    });
  },

  handleQuestionType() {
    if (!this.$question_type_select.length) { return; }
    const type = this.$question_type_select.val().split('::').pop();
    this.$question_type_options.addClass('hidden');
    switch (type) {
      case 'Text':
        return this.clearRangeInputOptions();
      case 'RangeInput':
        this.hideQuestionTypes('RangeInput');
        return this.showQuestionTypes('RangeInput');
      default:
        this.hideQuestionTypes(type);
        this.showQuestionTypes(type);
        return this.clearRangeInputOptions();
    }
  },

  hideQuestionTypes(string) {
    return $(`[data-question-type-options-hide-if*='${string}']`).addClass('hidden');
  },

  showQuestionTypes(string) {
    $(`[data-question-type-options*='${string}']`).removeClass('hidden');
    if (this.course_data) { this.$answer_options.addClass('hidden'); }

    switch (string) {
      case 'Select': case 'Checkbox': case 'Radio':
        if (!this.course_data) { return this.$answer_options.removeClass('hidden'); }
        break;
      case 'Long': case 'Short':
        return this.$answer_options.addClass('hidden');
      default:
        // no default
    }
  },

  handleConditionalSelect(e) {
    const id = e.target.value;
    if (id !== '') {
      this.conditional = {};
      this.conditional.question_id = id;
      return this.getQuestion(id);
    }
  },

  clearRangeInputOptions() {
    return this.$range_input_options.find('input').val('');
  },

  getQuestion(id) {
    return $.ajax({
      url: `/surveys/question_group_question/${id}`,
      method: 'get',
      dataType: 'json',
      contentType: 'application/json',
      success: $.proxy(this, 'handleConditionalQuestionSelect')
    });
  },

  handleConditionalQuestionSelect(e) {
    this.clearConditionalOperatorAndValue();
    switch (e.question_type) {
      case 'long': case 'short':
        return this.textConditional(e.question);
      case 'rangeinput':
        return this.comparisonConditional(e.question);
      default:
        return this.multipleChoiceConditional(e.question);
    }
  },

  handleCourseDataCheckboxChange({ target }) {
    const $courseData = $('[data-question-type-field="course_data"]');
    if (target.checked) {
      this.course_data = true;
      $courseData.removeClass('hidden');
      return this.$answer_options.addClass('hidden');
    }
    this.course_data = false;
    this.$course_data_type_select.prop('selectedIndex', 0);
    $courseData.addClass('hidden');
    return this.$answer_options.removeClass('hidden');
  },

  handleFollowUpCheckboxChange({ target }) {
    const $option = $('[data-question-type-field="follow_up_question"]');
    if (target.checked) {
      return $option.removeClass('hidden');
    }
    return $option.addClass('hidden');
  },

  handleMatrixCheckboxChange({ target }) {
    const $option = $('[data-question-type-field="matrix"]');
    if (target.checked) {
      return $option.removeClass('hidden');
    }
    return $option.addClass('hidden');
  },

  handleConditionalCheckboxChange({ target }) {
    const $option = $('[data-conditional-options]');
    if (target.checked) {
      return $option.removeClass('hidden');
    }
    return $option.addClass('hidden');
  },

  textConditional() {
    this.$conditional_operator.text('is present');
    return this.addPresenceConditional();
  },

  comparisonConditional() {
    this.$conditional_operator_select.append(CONDITIONAL_COMPARISON_OPERATORS).removeClass('hidden');
    this.$conditional_value_number_field.removeClass('hidden');
    return this.$conditional_value_number_field.on('blur', e => {
      let conditionalString = '';
      conditionalString += `${this.$conditional_question_select.val()}|`;
      conditionalString += `${this.$conditional_operator_select.val()}|`;
      conditionalString += e.target.value;
      return this.$conditional_input_field.val(conditionalString);
    });
  },

  multipleChoiceConditional(question) {
    this.$conditional_operator.text('=');
    this.conditional.operator = '=';
    this.$clear_conditional_button.removeClass('hidden');
    const answers = question.answer_options.split('\n');
    this.$conditional_value_select.append("<option value='nil' slelected>Select an Answer</option>");
    answers.map((answer) => {
      const answerValue = answer.trim();
      return this.$conditional_value_select.append(`<option value='${this.sanitizeAnswerValue(answerValue)}'>${answerValue}</option>`);
    });
    this.$conditional_value_select.removeClass('hidden');
    return this.$document.trigger(CONDITIONAL_ANSWERS_CHANGED);
  },

  sanitizeAnswerValue(string) {
    return striptags(string).replace('\'', '&#39;').replace('"', '&#34;').split(' ').join('_');
  },
  // string.replace('\'', '&#39;').replace('\"', '&#34;')


  handleConditionalAnswerSelect({ target }) {
    if (target.value !== 'nil') {
      this.conditional.answer_value = target.value;
      return this.addMultiConditional();
    }
  },

  initConditionals() {
    return $('[data-conditional]').each((i, conditionalRow) => {
      const $row = $(conditionalRow);
      const string = $row.data('conditional');
      if (string === '') { return; }
      const { question_id, operator, value } = Utils.parseConditionalString(string);
      switch (operator) {
        case '<': case '<=': case '>': case '>=':
          // eslint-disable-next-line camelcase
          $row.find('select').val(`${question_id}`);
          this.$conditional_operator_select.append(CONDITIONAL_COMPARISON_OPERATORS).removeClass('hidden');
          this.$conditional_operator_select.val(operator).trigger('change').removeClass('hidden');
          return this.$conditional_value_number_field.val(value).removeClass('hidden');
        default:
          this.$conditional_operator.text(operator);
          this.$document.on(CONDITIONAL_ANSWERS_CHANGED, () => {
            this.$conditional_value_select.val(value).trigger('change');
            return this.$document.off(CONDITIONAL_ANSWERS_CHANGED);
          });
          // eslint-disable-next-line camelcase
          return $row.find('select').val(`${question_id}`).trigger('change');
      }
    });
  },

  addPresenceConditional() {
    return this.$conditional_input_field.val(`${this.$conditional_question_select.val()}|*presence`);
  },

  addMultiConditional(e) {
    if (e) { e.preventDefault(); }
    let conditionalString = '';
    conditionalString += `${this.$conditional_question_select.val()}|`;
    conditionalString += `${this.$conditional_operator.text()}|`;
    conditionalString += `${this.$conditional_value_select.val()}|multi`;
    return this.$conditional_input_field.val(conditionalString);
  },

  clearConditional(e) {
    if (e) { e.preventDefault(); }
    this.$conditional_operator.text('');
    this.$conditional_question_select.prop('selectedIndex', 0);
    this.clearConditionalOperatorAndValue();
    return this.$conditional_input_field.val(null);
  },

  clearConditionalOperatorAndValue() {
    this.$conditional_value_select.addClass('hidden').prop('selectedIndex', 0);
    this.$clear_conditional_button.addClass('hidden');
    this.$conditional_value_number_field.val('').addClass('hidden');
    return this.$conditional_operator_select.off('blur').empty().addClass('hidden');
  },

  initSearchableList() {
    const options = {
      valueNames: ['name', 'status', 'author'],
    };
    const listObj = new List('searchable-list', options); // eslint-disable-line no-undef
    return listObj;
  },

  initMarkdown() {
    const updateMarkdownTabs = function (source, $preview, $source) {
      $preview.html(source);
      return $source.text(source);
    };

    $('[data-markdown-source]').each((i, text) => {
      const $text = $(text);
      const id = $text.data('markdown-source');
      const $preview = $(`[data-markdown-preview='${id}']`);
      const $source = $(`[data-markdown-source-view='${id}']`);
      const update = function () {
        const html = markdown.render($text.val());
        return updateMarkdownTabs(html, $preview, $source);
      };
      update();
      return $text.keyup(update);
    });

    return $('[data-render-markdown-label]').each((i, text) => {
      const $text = $(text);
      const $target = $text.next('[data-markdown-target]');
      return $target.html(markdown.render($text.data('render-markdown-label')));
    });
  }
};

export default SurveyAdmin;
