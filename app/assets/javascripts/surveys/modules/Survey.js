//--------------------------------------------------------
// Vendor Requirements
//--------------------------------------------------------

require('velocity-animate');
require('parsleyjs');
require('core-js/modules/es6.array.is-array');
const rangeslider = require('nouislider');
require('wnumb');
const throttle = require('lodash.throttle');
import UrlParse from 'url-parse';



//--------------------------------------------------------
// Required Internal Modules
//--------------------------------------------------------

const Utils = require('./SurveyUtils.coffee');

//--------------------------------------------------------
// Survey Module Misc Options
//--------------------------------------------------------

// Scroll Animation
const scrollDuration = 500;
const scrollEasing = [0.19, 1, 0.22, 1];


const chosenOptions = {
  disable_search_threshold: 10,
  width: '75%'
};


//--------------------------------------------------------
// Survey Module
//--------------------------------------------------------

const Survey = {

  currentBlock: 0,
  submitted: [],
  surveyConditionals: {},
  previewMode: false,

  init() {
    this.$window = $(window);
    scroll(0, 0);
    this.$surveyForm = $('[data-survey-form]');
    this.surveyBlocks = $('[data-survey-block]');
    this.$intro = $('[data-intro]');
    this.$thankYou = $('[data-thank-you]');
    this.setFormValidationSections();
    this.surveyProgress = $('[data-survey-progress]');
    this.getUrlParam();
    this.removeUnneededBlocks();
    this.initConditionals();
    this.listeners();
    this.initBlocks();
    this.initRangeSliders();
  },

  listeners() {
    $('[data-next-survey]').on('click', this.nextSurvey.bind(this));
    $('[data-next-survey-block]').on('click', this.validateCurrentQuestion.bind(this));
    $('[data-chosen-select]').chosen(chosenOptions);
    this.$window.scroll(throttle(this.handleScroll.bind(this), 250));
  },

  handleScroll() {
    if (this.animating) { return; }
    const distanceToTop = this.$window.scrollTop();
    const windowHeight = this.$window.innerHeight();
    const threshold = (distanceToTop + windowHeight) - (windowHeight * 0.5);

    return this.surveyBlocks.each((i, block) => {
      const $block = $(block);
      if ($block.hasClass('not-seen')) { return; }
      const blockOffset = $block.offset().top;
      if (blockOffset > distanceToTop && blockOffset < threshold) {
        $block.removeClass('disabled');
      } else {
        $block.addClass('disabled');
      }
    });
  },

  initBlocks() {
    this.indexBlocks();
    window.scrollTo(0, 0);
    $(this.surveyBlocks[this.currentBlock]).removeClass('disabled not-seen');
  },

  indexBlocks(cb = null) {
    $('.block[data-survey-block].hidden').removeAttr('data-survey-block');
    const $surveyBlocks = $('.block[data-survey-block]:not(.hidden)');
    $surveyBlocks.each((i, block) => {
      const $block = $(block);
      $block.attr('data-survey-block', i);
    });

    if (cb) { return cb(); }
  },

  nextSurvey(e) {
    e.preventDefault();
    if ($(e.target).data('next-survey')) { // Last Survey
      this.submitAllQuestionGroups();
      this.showThankYou();
    } else {
      $(e.target).parents('.block').addClass('hidden');
      this.nextBlock();
    }
  },

  submitAllQuestionGroups() {
    if (!this.previewMode) {
      this.dismissSurvey();
      this.$surveyForm.each(this.submitQuestionGroup.bind(this));
    }
  },

  submitQuestionGroup(index) {
    if (this.submitted.indexOf(index) !== -1) { return; }
    this.submitted.push(index);
    const $form = $(`form[data-question-group='${index}']`);
    const url = $form.attr('action');
    const method = $form.attr('method');
    const _context = this;

    $form.on('submit', function (e) {
      e.preventDefault();
      const data = _context.processQuestionGroupData($(this).serializeArray());
      return $.ajax({
        url,
        method,
        data: JSON.stringify(data),
        dataType: 'json',
        contentType: 'application/json',
        // success(d) { return console.log('success', d); },
        // error(er) { return console.log('error', er); }
      });
    });

    $form.submit();
  },

  getUrlParam() {
    let key;
    if (location.search.length) {
      const params = new UrlParse(location.href, true).query;
      const paramHandler = {
        notification: (val) => {
          this.surveyNotificationId = val;
        },
        preview: () => {
          this.previewMode = true;
        }
      };
      for (key in params) {
        if (typeof paramHandler[key] !== 'undefined') {
          paramHandler[key](params[key]);
        }
      }
    }
    return null;
  },

  dismissSurvey() {
    if (this.surveyNotificationId === undefined) { return; }
    $.ajax({
      type: 'PUT',
      url: '/survey_notification',
      dataType: 'json',
      data: {
        survey_notification: {
          id: this.surveyNotificationId,
          notification_dismissed: true
        }
      },
      success(data) {
        console.log(data);
      }
    });
  },

  processQuestionGroupData(data) {
    const _postData = {};
    const answerGroup = {};
    data.forEach((field) => {
      const name = field.name;
      const value = field.value;
      const val = {};
      const answerText = {};
      if (name.indexOf('answerGroup') !== -1) {
        const fielddata = name.replace('answerGroup', '').split('[');
        const answerId = fielddata[1].replace(']', '');
        const answerKey = fielddata[2].replace(']', '');
        if (name.indexOf('[]') === -1) { // Single Answer Question
          val[answerKey] = value;
          answerGroup[answerId] = val;
        } else { // Multi-Select (Checkbox)
          if (value !== '0') {
            if ((answerGroup[answerId] !== null)) {
              answerGroup[answerId][answerKey].push('0');
              answerGroup[answerId][answerKey].push(value);
            } else {
              answerText[answerKey] = ['0', value];
              return answerGroup[answerId] = answerText;
            }
          }
        }
      } else {
        _postData[name] = value;
      }
    });

    _postData.answer_group = answerGroup;
    return _postData;
  },

  updateCurrentBlock() {
    const $block = $(`[data-survey-block='${this.currentBlock}']`);
    if (this.animating) { return; }
    $($block).velocity('scroll', {
      duration: scrollDuration,
      easing: scrollEasing,
      offset: -200,
      begin: () => {
        return $(this.surveyBlocks[this.currentBlock]).removeClass('highlight').attr('style', '');
      },
      complete: () => {
        this.animating = false;
        return this.focusField();
      }
    });
    if ($block.hasClass('not-seen')) {
      $block.velocity({
        opacity: [1, 0],
        translateY: ['0%', '100%']
      }, {
        queue: false,
        complete() {
          $block.removeClass('not-seen disabled');
        }
      });
    }
  },

  nextBlock() {
    const toIndex = this.currentBlock + 1;
    const $block = $(`[data-survey-block='${toIndex}']`);
    if (this.animating) { return; }
    $($block).velocity('scroll', {
      duration: scrollDuration,
      easing: scrollEasing,
      offset: -200,
      begin: () => {
        $(this.surveyBlocks[this.currentBlock]).removeClass('highlight').attr('style', '');
        this.updateProgress(toIndex);
      },
      complete: () => {
        this.animating = false;
        this.currentBlock = toIndex;
        return this.focusField();
      }
    });
    if ($block.hasClass('not-seen')) {
      $block.velocity({
        opacity: [1, 0],
        translateY: ['0%', '100%']
      }, {
        queue: false,
        complete() {
          return $block.removeClass('not-seen');
        }
      });
    }
  },

  validateCurrentQuestion(e) {
    e.preventDefault();
    let $form = this.$surveyForm;
    const $block = $(this.surveyBlocks[this.currentBlock]);
    const $errorsEl = $block.find('[data-errors]');
    const questionGroupIndex = this.currentQuestionGroupIndex();
    let validation = $form.parsley({ uiEnabled: false }).validate({ group: `${$block.data('parsley-group')}` });

    if (($(e.target).closest('.button').data('no-validate') !== null)) {
      this.nextBlock(e);
      return;
    }

    if ((typeof questionGroupIndex !== 'undefined' && questionGroupIndex !== null)) {
      $form = $(this.$surveyForm[questionGroupIndex]);
    }

    if ($block.find("[data-required-checkbox='true']").length) {
      if ($block.find('input[type="checkbox"]:checked').length === 0) {
        validation = false;
      }
    }

    // Ensure Course Select has a valid value (See CourseDataQuestions)
    if ($(e.target).closest('.button').data('next-survey-block') === 'course') {
      if ($('#course').val() === '') {
        validation = false;
      }
    }

    if (validation === true) {
      $errorsEl.empty();
      this.removeNextButton(e);
      this.nextBlock(e);
    } else {
      this.handleRequiredQuestion();
    }
  },

  currentQuestionGroupIndex() {
    $(this.surveyBlocks[this.currentBlock]).find('[data-question-group]').first().data('question-group');
  },

  setFormValidationSections() {
    this.surveyBlocks.each((i, block) => {
      const $block = $(block);
      $block.attr('data-parsley-group', `block${i}`);
      return $block.find(':input').attr('data-parsley-group', `block${i}`);
    });
  },

  handleRequiredQuestion() {
    return $(this.surveyBlocks[this.currentBlock]).addClass('highlight');
  },

  focusField() {
    return $(this.surveyBlocks[this.currentBlock]).find('input, textarea').first().focus();
  },

  updateProgress(index) {
    const width = `${(index / (this.surveyBlocks.length - 1)) * 100}%`;
    this.surveyProgress.css('width', width);
  },

  removeNextButton({ target }) {
    const $el = $(target).closest('.button');
    if (!(typeof target !== 'undefined' && target !== null)) { return; }
    if ($el.hasClass('button')) {
      $el.addClass('hidden');
    }
  },

  initRangeSliders() {
    $('[data-range]').each((i, slider) => {
      const $input = $(slider).next('[data-range-field]');
      const min = parseInt($(slider).data('min'));
      const max = parseInt($(slider).data('max'));
      const step = parseInt($(slider).data('step'));
      const divisions = $(slider).data('divisions');
      const format = $(slider).data('format');

      const numberFormatting = (() => {
        switch (format) {
          case '%':
            return {
              decimals: 0,
              postfix: '%'
            };
          case '$':
            return {
              decimals: 0,
              prefix: '$'
            };
          default:
            return {};
        }
      })();

      rangeslider.create(slider, {
        start: 0,
        range: { min, max },
        step,
        pips: {
          mode: 'count',
          values: 5,
          density: (typeof divisions !== 'undefined' && divisions !== null) ? parseInt(divisions) : 4,
          format: wNumb(numberFormatting)
        },
        connect: 'lower'
      });

      slider.noUiSlider.on('change', (value) => {
        $input.val(parseInt(value[0])).trigger('change');
      });
    });
  },

  showThankYou() {
    this.$surveyForm.addClass('hidden');
    this.$intro.addClass('hidden');
    this.$thankYou.velocity('scroll', {
      duration: scrollDuration,
      easing: scrollEasing,
      offset: -200,
      complete: () => {
        return this.animating = false;
      }
    });

    this.$thankYou.velocity({
      opacity: [1, 0],
      translateY: ['0%', '20%']
    }, {
      queue: false
    });
  },

  initConditionals() {
    $('[data-conditional-question]').each((i, question) => {
      const $conditionalQuestion = $(question);
      let $question = $($(question).parents('.block'));
      const { question_id, operator, value, multi } = Utils.parseConditionalString($conditionalQuestion.data('conditional-question'));
      if (this.isMatrixBlock($question)) {
        $question = $conditionalQuestion;
      }

      $question.addClass('hidden');

      if (typeof this.surveyConditionals[question_id] !== 'undefined') {
        this.surveyConditionals[question_id].children.push($question[0]);
      } else {
        this.surveyConditionals[question_id] = {};
        this.surveyConditionals[question_id].children = [$question[0]];
      }

      if ((typeof value !== 'undefined' && value !== null)) { this.surveyConditionals[question_id][value] = $question; }
      this.surveyConditionals[question_id].currentAnswers = [];

      switch (operator) {
        case '*presence':
          return this.conditionalPresenceListeners(question_id, $question);
        case '<': case '>':case '<=': case '>=':
          return this.conditionalComparisonListeners(question_id, operator, value, $question);
        default:
          return this.conditionalAnswerListeners(question_id, multi);
      }
    });
  },

  conditionalAnswerListeners(id, multi) {
    // @surveyConditionals[id].operator = operator
    $(`#question_${id} input, #question_${id} select`).on('change', ({ target }) => {
      let value = $(target).val();
      const $parent = $(`#question_${id}`);
      const $checkedInputs = $parent.find('input:checked');
      if (multi && $checkedInputs.length) {
        value = [];
        $checkedInputs.each((i, input) => {
          return value.push($(input).val());
        });
      } else if (multi) {
        value = [];
      }

      this.handleParentConditionalChange(value, this.surveyConditionals[id], $parent, multi);
    });
  },

  conditionalComparisonListeners(id, operator, value) {
    const validateExpression = {
      ['>'](a, b) { return a > b; },
      ['>='](a, b) { return a >= b; },
      ['<'](a, b) { return a < b; },
      ['<='](a, b) { return a <= b; }
    };

    const $parent = $(`#question_${id}`);
    const conditionalGroup = this.surveyConditionals[id];
    const $questionBlock = $(conditionalGroup[value]);


    $(`#question_${id} input`).on('change', ({ target }) => {
      $parent.find('.survey__next.hidden').removeClass('hidden');
      if (validateExpression[operator](parseInt(target.value), parseInt(value))) {
        this.resetConditionalGroupChildren(conditionalGroup);
        this.activateConditionalQuestion($questionBlock);
      } else {
        this.resetConditionalQuestion($questionBlock);
      }

      this.indexBlocks();
      this.setToCurrentBlock($parent);
    });
  },

  handleParentConditionalChange(value, conditionalGroup, $parent) {
    let currentAnswers = conditionalGroup.currentAnswers;
    let conditional;
    // let resetQuestions = false;

    if (Array.isArray(value)) {
      // Check if empty
      if (value.length === 0 && currentAnswers) {
        conditionalGroup.currentAnswers = [];
        // resetQuestions = true;
      }

      // Check if conditional was present and is no longer
      currentAnswers.forEach((a) => {
        if (value.indexOf(a === -1)) {
          // resetQuestions = true;
          const index = currentAnswers.indexOf(a);
          if (currentAnswers.length === 1) {
            currentAnswers = [];
          } else {
            currentAnswers = currentAnswers.slice(index, index + 1);
          }
        }
      });

      // Check if value matches a conditional question
      value.forEach((v) => {
        if ((conditionalGroup[v] !== null)) {
          conditional = conditionalGroup[v];
          currentAnswers.push(v);
          return conditionalGroup.currentAnswers = currentAnswers;
        }
      });

      if (currentAnswers.length === 0) {
        conditionalGroup.currentAnswers = [];
      }
    } else {
      conditional = conditionalGroup[value];
      // resetQuestions = true;
    }

    this.resetConditionalGroupChildren(conditionalGroup);

    if ((typeof conditional !== 'undefined' && conditional !== null)) {
      this.activateConditionalQuestion($(conditional));
    }

    this.indexBlocks();
    this.setToCurrentBlock($parent);

    $parent.find('.survey__next.hidden').removeClass('hidden');
  },

  conditionalPresenceListeners(id, question) {
    this.surveyConditionals[id].present = false;
    this.surveyConditionals[id].question = question;
    $(`#question_${id} textarea`).on('keyup', ({ target }) => {
      this.handleParentPresenceConditionalChange({
        present: target.value.length,
        conditionalGroup: this.surveyConditionals[id],
        $parent: $(`#question_${id}`)
      });
    });
  },

  handleParentPresenceConditionalChange(params) {
    const { present, conditionalGroup, $parent } = params;
    const $question = $(conditionalGroup.question);
    this.setToCurrentBlock($parent);

    if (present && !conditionalGroup.present) {
      conditionalGroup.present = true;
      this.activateConditionalQuestion($question);
    } else if (!present && conditionalGroup.present) {
      conditionalGroup.present = false;
      this.resetConditionalQuestion($question);
    }

    $parent.find('.survey__next.hidden').removeClass('hidden');

    this.indexBlocks();
    this.setToCurrentBlock($parent);
    this.updateCurrentBlock();
  },

  resetConditionalGroupChildren(conditionalGroup) {
    const { children, currentAnswers } = conditionalGroup;

    if ((typeof currentAnswers !== 'undefined' && currentAnswers !== null) && currentAnswers.length) {
      const excludeFromReset = [];
      currentAnswers.map((a) => { return excludeFromReset.push(a); });
      children.forEach((question) => {
        let string;
        if ($(question).hasClass('survey__question-row')) {
          this.activateConditionalQuestion($(question).parents('.block'));
        }
        if ($(question).data('conditional-question')) {
          string = $(question).data('conditional-question');
        } else {
          string = $(question).find('[data-conditional-question]').data('conditional-question');
        }
        const { value } = Utils.parseConditionalString(string);
        if (excludeFromReset.indexOf(value) === -1) {
          this.resetConditionalQuestion($(question));
        }
      });
    } else {
      children.forEach((question) => {
        this.resetConditionalQuestion($(question));
        if ($(question).hasClass('survey__question-row')) {
          const $parentBlock = $(question).parents('.block');
          if (!($parentBlock.find('.survey__question-row:not([data-conditional-question])').length > 1)) {
            this.resetConditionalQuestion($parentBlock);
          }
        }
      });
    }
  },

  resetConditionalQuestion($question) {
    $question.removeAttr('style').addClass('hidden not-seen disabled');
    $question.find('input, textarea').val('');
    $question.find('input:checked').removeAttr('checked');
    $question.find('select').prop('selectedIndex', 0);
    $question.find('.survey__next.hidden').removeClass('hidden');
  },

  activateConditionalQuestion($question) {
    $question.removeClass('hidden');
    if ($question.hasClass('block')) {
      $question.attr('data-survey-block', '');
    }
  },

  setToCurrentBlock($block) {
    this.currentBlock = $block.data('survey-block');
  },

  isMatrixBlock($block) {
    $block.hasClass('survey__question--matrix');
  },

  removeUnneededBlocks() {
    $('[data-remove-me]').parents('.block').remove();
  }
};


export default Survey;
