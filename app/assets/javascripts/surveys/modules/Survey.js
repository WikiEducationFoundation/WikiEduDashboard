//--------------------------------------------------------
// Vendor Requirements
//--------------------------------------------------------

require('velocity-animate');
require('parsleyjs');
require('core-js/modules/es6.array.is-array');
const rangeslider = require('nouislider');
require('wnumb');
const wNumb = window.wNumb;
require('slick-carousel');
require('velocity-animate');

//--------------------------------------------------------
// Required Internal Modules
//--------------------------------------------------------

const Utils = require('./SurveyUtils.coffee');

//--------------------------------------------------------
// Survey Module Misc Options
//--------------------------------------------------------

// Scroll Animation
// const scrollDuration = 500;
const scrollEasing = [0.19, 1, 0.22, 1];


const chosenOptions = {
  disable_search_threshold: 10,
  width: '75%'
};

const slickOptions = {
  infinite: false,
  arrows: false,
  draggable: false,
  touchMove: false,
  cssEase: 'cubic-bezier(1, 0, 0, 1)',
};


//--------------------------------------------------------
// Constants
//--------------------------------------------------------

const BLOCK_CONTAINER_SELECTOR = '.block__container';

//--------------------------------------------------------
// Survey Module
//--------------------------------------------------------

const Survey = {

  currentBlock: 0,
  submitted: [],
  surveyConditionals: {},
  previewMode: false,
  detachedParentBlocks: {},

  init() {
    this.cacheSelectors();
    this.getUrlParam();
    this.removeUnneededBlocks();
    this.initConditionals();
    this.listeners();
    this.initBlocks();
    this.initRangeSliders();
    this.setFormValidationSections();
  },

  cacheSelectors() {
    this.$window = $(window);
    this.$surveyForm = $('[data-survey-form]');
    this.surveyBlocks = $('[data-survey-block]');
    this.$intro = $('[data-intro]');
    this.$thankYou = $('[data-thank-you]');
    this.surveyProgress = $('[data-survey-progress]');
    this.$main = $('#main');
  },

  listeners() {
    $('[data-next-survey]').on('click', this.nextSurvey.bind(this));
    this.$main.on('click', '[data-next-survey-block]', this.validateCurrentQuestion.bind(this));
    this.$main.on('click', '[data-prev-survey-block]', this.previousBlock.bind(this));
    $('[data-submit-survey]').on('click', this.submitAllQuestionGroups.bind(this));
    $('[data-chosen-select]').chosen(chosenOptions);
    $('[data-void-checkboxes]').on('click', this.voidCheckboxSelections.bind(this));
    $('.survey__multiple-choice-field input[type=checkbox]').on('change', this.uncheckVoid.bind(this));
    $('.block input, .block textarea, .block select').on('change keydown', this.removeErrorState.bind(this));
  },

  initBlocks() {
    this.indexBlocks();
    this.initSlider();
    window.scrollTo(0, 0);
    $(this.surveyBlocks[this.currentBlock]).removeClass('disabled not-seen');
  },

  indexBlocks(cb = null) {
    // $('.block[data-survey-block].hidden').removeAttr('data-survey-block');
    // const $surveyBlocks = $('.block[data-survey-block]:not(.hidden)');
    // $surveyBlocks.each((i, block) => {
    //   const $block = $(block);
    //   $block.attr('data-survey-block', i);
    // });
    //
    // this.$questionBlocks = $surveyBlocks;

    if (cb) { return cb(); }
  },

  initSlider() {
    this.parentSlider = $('[data-survey-form-container]').slick(slickOptions);
    this.groupSliders = [];
    $('[data-question-group-blocks]').each((i, questionGroup) => {
      const slider = $(questionGroup).slick(slickOptions);
      $(slider).on('afterChange', (e, slick, currentSlide) => {
        this.currentBlock = currentSlide;
        $('.block__container.slick-active').velocity('scroll', {
          easing: scrollEasing
        });
      });
      this.groupSliders.push(slider);
    });
    $(this.parentSlider).removeClass('loading');
  },

  prevQuestionGroup() {
    $(this.parentSlider).slick('slickPrev');
  },

  nextQuestionGroup() {
    $(this.parentSlider).slick('slickNext');
  },

  nextBlock() {
    const $slider = $(this.$currentSlider);
    const $slick = $slider.slick('getSlick');
    if ($slick.currentSlide === undefined || ($slick.currentSlide + 1) === $slick.slideCount) {
      this.nextQuestionGroup();
    } else {
      $slider.slick('slickNext');
    }
  },

  previousBlock(e) {
    e.preventDefault();
    const $slider = $(this.$currentSlider);
    const $slick = $slider.slick('getSlick');
    if (($slick.currentSlide - 1) === -1) {
      this.prevQuestionGroup();
    } else {
      $slider.slick('slickPrev');
    }
  },

  nextSurvey(e) {
    e.preventDefault();
  },

  submitAllQuestionGroups() {
    if (!this.previewMode) {
      this.updateSurveyNotification();
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
    if (location.search.length && location.search.replace('?', '') === 'preview') {
      this.previewMode = true;
    }
  },

  updateSurveyNotification() {
    if (this.surveyNotificationId === undefined) { return; }
    $.ajax({
      type: 'PUT',
      url: '/survey_notification',
      dataType: 'json',
      data: {
        survey_notification: {
          id: this.surveyNotificationId,
          dismissed: true,
          completed: true
        }
      },
      success() {
        // console.log(data);
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
      if (name.indexOf('answer_group') !== -1) {
        const fielddata = name.replace('answerGroup', '').split('[');
        const answerId = fielddata[1].replace(']', '');
        const answerKey = fielddata[2].replace(']', '');
        if (name.indexOf('[]') === -1) { // Single Answer Question
          val[answerKey] = value;
          answerGroup[answerId] = val;
        } else { // Multi-Select (Checkbox)
          if (value !== '0') {
            if (typeof answerGroup[answerId] !== 'undefined') {
              answerGroup[answerId][answerKey].push('0');
              answerGroup[answerId][answerKey].push(value);
            } else {
              answerText[answerKey] = ['0', value];
              answerGroup[answerId] = answerText;
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

  },
  validateCurrentQuestion(e) {
    e.preventDefault();
    const $target = $(e.target);
    const $block = $target.parents('.block');
    this.$currentBlock = $block;
    let $form = $block.parents('[data-survey-form]');
    this.$currentSlider = $form.find('[data-question-group-blocks]');
    const $errorsEl = $block.find('[data-errors]');
    const questionGroupIndex = this.currentQuestionGroupIndex();

    if ($target.closest('.button').data('no-validate') !== undefined) {
      this.nextBlock(e);
      return;
    }

    let validation = $form.parsley({ uiEnabled: false })
                          .validate({ group: `${$block.data('parsley-group')}` });

    if ((typeof questionGroupIndex !== 'undefined' && questionGroupIndex !== null)) {
      $form = $(this.$surveyForm[questionGroupIndex]);
    }

    // Validate Checkbox
    if ($block.find('[data-required-checkbox]').length &&
        $block.find('input[type="checkbox"]:checked').length === 0) {
      validation = false;
    }

    // Validate Required Matrix Question Rows
    if ($block.hasClass('survey__question--matrix')) {
      this.validateMatrixBlock($block, (bool) => {
        validation = bool;
      });
    }

    if (validation === true) {
      $block.removeClass('highlight');
      $errorsEl.empty();
      this.nextBlock(e);
    } else {
      this.handleRequiredQuestion($errorsEl);
    }
  },

  validateMatrixBlock($block, cb) {
    let valid = true;
    $block.find('.survey__question-row.required').each((i, row) => {
      const $row = $(row);
      if ($row.find('input:checked').length === 0) {
        $row.addClass('highlight');
        valid = false;
      }
    });

    if (valid) {
      cb(true);
    } else {
      cb(false);
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

  handleRequiredQuestion($errorsEl) {
    $errorsEl.append('<span>Question Required</span>');
    this.$currentBlock.addClass('highlight');
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

      $input.on('change', ({ target }) => {
        slider.noUiSlider.set(target.value);
      });
    });
  },

  showThankYou() {
    // this.$surveyForm.addClass('hidden');
    // this.$intro.addClass('hidden');
    // this.$thankYou.velocity('scroll', {
    //   duration: scrollDuration,
    //   easing: scrollEasing,
    //   offset: -200,
    //   complete: () => {
    //     return this.animating = false;
    //   }
    // });
    //
    // this.$thankYou.velocity({
    //   opacity: [1, 0],
    //   translateY: ['0%', '20%']
    // }, {
    //   queue: false
    // });
  },

  initConditionals() {
    $('[data-conditional-question]').each((i, question) => {
      const $conditionalQuestion = $(question);
      let $question = $($(question).parents(BLOCK_CONTAINER_SELECTOR));
      const { question_id, operator, value, multi } = Utils.parseConditionalString($conditionalQuestion.data('conditional-question'));

      if ($question.find('.survey__question--matrix').length) {
        this.detachedParentBlocks[$question.data('block-index')] = $question;
        $question.detach();
        $question = $conditionalQuestion;
        $question.addClass('hidden');
      } else {
        $question.detach();
      }

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
      let value = $(target).val().split(' ').join('_');

      const $parent = $(`#question_${id}`).parent('.block__container');
      const $checkedInputs = $parent.find('input:checked');
      if (multi && $checkedInputs.length) {
        value = [];
        $checkedInputs.each((i, input) => {
          value.push($(input).val().trim().split(' ').join('_'));
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

    const $parent = $(`#question_${id}`).parent('.block__container');
    const conditionalGroup = this.surveyConditionals[id];
    const $questionBlock = $(conditionalGroup[value]);


    $(`#question_${id} input`).on('change', ({ target }) => {
      $parent.find('.survey__next.hidden').removeClass('hidden');
      if (validateExpression[operator](parseInt(target.value), parseInt(value))) {
        this.resetConditionalGroupChildren(conditionalGroup);
        this.activateConditionalQuestion($questionBlock, $parent);
      } else {
        this.resetConditionalQuestion($questionBlock);
      }

      this.indexBlocks();
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
      }

      // Check if conditional was present and is no longer
      currentAnswers.forEach((a) => {
        if (value.indexOf(a === -1)) {
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
        if (conditionalGroup[v] !== undefined) {
          conditional = conditionalGroup[v];
          currentAnswers.push(v);
          conditionalGroup.currentAnswers = currentAnswers;
        }
      });

      if (currentAnswers.length === 0) {
        conditionalGroup.currentAnswers = [];
      }
    } else {
      conditional = conditionalGroup[value];
    }

    this.resetConditionalGroupChildren(conditionalGroup);

    if (typeof conditional !== 'undefined' && conditional !== null) {
      this.activateConditionalQuestion($(conditional), $parent);
    }

    // this.indexBlocks();

    // $parent.find('.survey__next.hidden').removeClass('hidden');
  },

  conditionalPresenceListeners(id, question) {
    this.surveyConditionals[id].present = false;
    this.surveyConditionals[id].question = question;
    $(`#question_${id} textarea`).on('keyup', ({ target }) => {
      this.handleParentPresenceConditionalChange({
        present: target.value.length,
        conditionalGroup: this.surveyConditionals[id],
        $parent: $(`#question_${id}`).parents(BLOCK_CONTAINER_SELECTOR)
      });
    });
  },

  handleParentPresenceConditionalChange(params) {
    const { present, conditionalGroup, $parent } = params;
    const $question = $(conditionalGroup.question);

    if (present && !conditionalGroup.present) {
      conditionalGroup.present = true;
      this.activateConditionalQuestion($question, $parent);
    } else if (!present && conditionalGroup.present) {
      conditionalGroup.present = false;
      this.resetConditionalQuestion($question);
    }
  },

  resetConditionalGroupChildren(conditionalGroup) {
    const { children, currentAnswers } = conditionalGroup;

    if ((typeof currentAnswers !== 'undefined' && currentAnswers !== null) && currentAnswers.length) {
      const excludeFromReset = [];
      currentAnswers.forEach((a) => { excludeFromReset.push(a); });
      children.forEach((question) => {
        const $question = $(question);
        let string;
        if ($question.data('conditional-question')) {
          string = $question.data('conditional-question');
        } else {
          string = $question.find('[data-conditional-question]').data('conditional-question');
        }
        const { value } = Utils.parseConditionalString(string);
        if (excludeFromReset.indexOf(value) === -1) {
          this.resetConditionalQuestion($question);
        } else {
          $question.removeClass('hidden');
        }
      });
    } else {
      children.forEach((question) => {
        this.resetConditionalQuestion($(question));
        if ($(question).hasClass('survey__question-row')) {
          const $parentBlock = $(question).parents(BLOCK_CONTAINER_SELECTOR);
          const blockIndex = $(question).data('block-index');
          if (!($parentBlock.find('.survey__question-row:not([data-conditional-question])').length > 1)) {
            this.resetConditionalQuestion($parentBlock);
            if (this.detachedParentBlocks[blockIndex] === undefined) {
              this.detachedParentBlocks[blockIndex] = $parentBlock;
              this.removeSlide($parentBlock);
              $parentBlock.detach();
            }
          }
        }
      });
    }
  },

  removeSlide($block) {
    const $slider = $(this.$currentSlider);
    $slider.slick('slickRemove', $block.data('slick-index') + 1);
  },

  resetConditionalQuestion($question) {
    if ($question.hasClass('survey__question-row')) {
      $question.removeAttr('style').addClass('hidden not-seen disabled');
    } else {
      $question.detach();
    }
    $question.find('input, textarea').val('');
    $question.find('input:checked').removeAttr('checked');
    $question.find('select').prop('selectedIndex', 0);
    $question.find('.survey__next.hidden').removeClass('hidden');
  },

  activateConditionalQuestion($question, $parent) {
    $question.removeClass('hidden');
    this.activateConditionalQuestionParent($parent);
    const $grandParents = $parent.parents('[data-question-group-blocks]');
    const parentIndex = $parent.data('slick-index');
    const questionGroupIndex = $grandParents.data('question-group-blocks');
    if ($question.hasClass('matrix-row')) {
      this.attachMatrixParentBlock($question, questionGroupIndex);
    } else {
      const $slider = this.groupSliders[questionGroupIndex];
      $slider.slick('slickAdd', $question, parentIndex);
    }
  },

  attachMatrixParentBlock($question, questionGroupIndex) {
    const $parent = $question.parents(BLOCK_CONTAINER_SELECTOR);
    const $parentBlock = this.detachedParentBlocks[$parent.data('block-index')];
    // If parent node is currently detached, re-add it to the question_group slider
    if (!$.contains(document, $parentBlock)) {
      const parentIndex = $parentBlock[0].dataset.blockIndex;
      const $slider = this.groupSliders[questionGroupIndex];
      $slider.slick('slickAdd', $parentBlock, (parentIndex - 1));
    }
  },

  activateConditionalQuestionParent($parent) {
    $parent.find('.block').removeClass('hidden');
  },

  isMatrixBlock($block) {
    $block.hasClass('survey__question--matrix');
  },

  removeUnneededBlocks() {
    $('[data-remove-me]').parents(BLOCK_CONTAINER_SELECTOR).remove();
  },

  voidCheckboxSelections(e) {
    const $target = $(e.target);
    $target.parents(BLOCK_CONTAINER_SELECTOR).find('input[type=checkbox]:checked').each((i, input) => {
      $(input).prop('checked', false);
    });
    $target.closest('input[type=checkbox]').prop('checked', true);
  },

  uncheckVoid(e) {
    const $target = $(e.target);
    if ($target.data('void-checkboxes')) { return; }
    $target.parents(BLOCK_CONTAINER_SELECTOR).find('input[data-void-checkboxes]').prop('checked', false);
  },

  removeErrorState(e) {
    const $block = $(e.target).parents('.block');
    if ($block.hasClass('highlight')) {
      $block.removeClass('highlight');
      $block.find('.survey__question-row.required.highlight').removeClass('highlight');
      $block.find('[data-errors]').empty();
    }
  }
};


export default Survey;
