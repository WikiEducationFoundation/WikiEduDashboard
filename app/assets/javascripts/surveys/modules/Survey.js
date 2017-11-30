//--------------------------------------------------------
// Vendor Requirements
//--------------------------------------------------------

require('velocity-animate');
require('parsleyjs');
require('core-js/modules/es6.array.is-array');
const rangeslider = require('nouislider');
const wNumb = require('wnumb');
require('slick-carousel');
require('velocity-animate');
// const markdown = require('../../utils/markdown_it.js').default();
import _throttle from 'lodash.throttle';
import _assign from 'lodash.assign';
import urlParse from 'url-parse';

//--------------------------------------------------------
// Required Internal Modules
//--------------------------------------------------------

import Utils from './SurveyUtils.js';

//--------------------------------------------------------
// Survey Module Misc Options
//--------------------------------------------------------

// Scroll Animation
// const scrollDuration = 500;
const scrollEasing = [0.19, 1, 0.22, 1];

const slickOptions = {
  infinite: false,
  arrows: false,
  accessibility: false,
  draggable: false,
  touchMove: false,
  speed: 400,
  cssEase: 'cubic-bezier(1, 0, 0, 1)',
  adaptiveHeight: true
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
  submittedAll: false,
  surveyConditionals: {},
  previewMode: false,
  detachedParentBlocks: {},
  currentBlockValidated: false,
  firstQuestionTabbed: false,

  init() {
    this.indexQuestionGroups();
    this.cacheSelectors();
    this.getUrlParam();
    this.removeUnneededBlocks();
    this.initConditionals();
    this.indexBlocks();
    this.listeners();
    this.initBlocks();
    this.initRangeSliders();
    this.setFormValidationSections();
    this.getNotificationId();
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
    this.$main.on('click', '[start-survey]', this.surveyStarted.bind(this));
    $(document).on('click', '[data-submit-survey]', this.submitAllQuestionGroups.bind(this));
    $('[data-void-checkboxes]').on('click', this.voidCheckboxSelections.bind(this));
    $('.survey__multiple-choice-field input[type=checkbox]').on('change', this.uncheckVoid.bind(this));
    $('.block input, .block textarea, .block select').on('change keydown', this.removeErrorState.bind(this));
  },

  surveyStarted() {
    try {
      // SurveyDetails is set in app/views/surveys/show.html.haml
      Raven.captureMessage(`Survey ${SurveyDetails.id} started`, { level: 'info' });
    } catch (e) {
      // nothing
    }
  },

  indexQuestionGroups() {
    $('[data-question-group-blocks]').each((i, qgBlock) => {
      $(qgBlock).data('question-group-blocks', i);
    });
  },

  initBlocks() {
    this.indexBlocks();
    this.initSlider();
    window.scrollTo(0, 0);
    $(this.surveyBlocks[this.currentBlock]).removeClass('disabled not-seen');
  },

  indexBlocks(cb = null) {
    $('.block__container').each((i, block) => {
      $(block).attr('data-progress-index', i + 1);
    });
    if (cb) { return cb(); }
  },

  initSlider() {
    this.$surveyContainer = $('[data-survey-form-container]');
    this.parentSlider = this.$surveyContainer.slick(_assign({}, slickOptions, { adaptiveHeight: false }));

    this.parentSlider.on('init', (e, slick) => {
      if (!this.firstQuestionTabbed) {
        this.toggleTabNavigationForQuestion(true, slick, slick.currentSlide);
        this.firstQuestionTabbed = true;
      }
    });
    this.parentSlider.on('beforeChange', (e, slick, currentSlide) => {
      if (!this.currentBlockValidated) {
        e.preventDefault();
      } else {
        this.toggleTabNavigationForQuestion(false, slick, currentSlide);
      }
    });
    this.parentSlider.on('afterChange', (e, slick, currentSlide) => {
      this.focusNewQuestion();
      const $currentBlock = $(slick.$slides[currentSlide]);
      this.updateProgress($currentBlock);
      this.toggleTabNavigationForQuestion(true, slick, currentSlide);
    });

    this.groupSliders = [];
    $('[data-question-group-blocks]').each((i, questionGroup) => {
      const slider = $(questionGroup).slick(slickOptions);
      $(slider).on('beforeChange', (e, slick, currentSlide) => {
        if (!this.currentBlockValidated) {
          e.preventDefault();
        } else {
          this.toggleTabNavigationForQuestion(false, slick, currentSlide);
        }
      });
      $(slider).on('afterChange', (e, slick, currentSlide) => {
        const $currentBlock = $(slick.$slides[currentSlide]);
        this.updateProgress($currentBlock);
        this.currentBlock = currentSlide;
        this.currentBlockValidated = false;
        this.focusNewQuestion();
        this.toggleTabNavigationForQuestion(true, slick, currentSlide);
      });
      this.groupSliders.push(slider);
    });
    $(this.parentSlider).removeClass('loading');
    this.updateButtonText();
  },

  toggleTabNavigationForQuestion(enable, slick, current) {
    const $slide = $(slick.$slides[current]);
    let $tabElements;
    if ($slide.hasClass('new_answer_group')) {
      $tabElements = $slide.find('.block__container:first [tabindex]');
    } else {
      $tabElements = $slide.find('[tabindex]');
    }
    const val = enable ? 0 : -1;
    $tabElements.each((i, el) => {
      $(el).prop('tabindex', val);
    });
  },

  focusNewQuestion() {
    $('.top-nav').velocity('scroll', {
      easing: scrollEasing
    });
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
    this.currentBlockValidated = true;
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
    try {
      Raven.captureMessage(`Survey ${SurveyDetails.id} submitted`, { level: 'info' });
    } catch (e) {
      // nothing
    }

    if (!this.previewMode) {
      this.updateSurveyNotification();
      this.$surveyForm.each(this.submitQuestionGroup.bind(this));
      this.submittedAll = true;
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
    const urlParams = urlParse(window.location.href, true).query;
    if (urlParams.preview !== undefined) {
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
      const { name } = field;
      const { value } = field;
      const val = {};
      const answerText = {};
      if (name.indexOf('answer_group') !== -1) {
        const fielddata = name.replace('answerGroup', '').split('[');
        const answerId = fielddata[1].replace(']', '');
        const answerKey = fielddata[2].replace(']', '');
        if (name.indexOf('[]') === -1) { // Single Answer Question
          if (typeof answerGroup[answerId] !== 'undefined') {
            answerGroup[answerId][answerKey] = value;
          } else {
            val[answerKey] = value;
            answerGroup[answerId] = val;
          }
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
      this.currentBlockValidated = true;
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
      this.currentBlockValidated = true;
      this.nextBlock(e);
    } else {
      this.handleRequiredQuestion($errorsEl);
    }
  },

  validateMatrixBlock($block, cb) {
    let valid = true;

    $block.find('.survey__question-row.required').each((i, row) => {
      const $row = $(row);

      if ($block.hasClass('radio')) {
        if ($row.find('input:checked').length === 0) {
          $row.addClass('highlight');
          valid = false;
        }
      }
      if ($block.hasClass('rangeinput')) {
        if ($row.find('input[type=number]').val() === '') {
          $row.addClass('highlight');
          valid = false;
        }
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
    this.currentBlockValidated = false;
    $errorsEl.empty().append('<span>Question Required</span>');
    this.$currentBlock.addClass('highlight');
  },

  focusField() {
    return $(this.surveyBlocks[this.currentBlock]).find('input, textarea').first().focus();
  },

  updateProgress($currentBlock) {
    const total = $('[data-progress-index]').length;
    let currentIndex;
    if ($currentBlock.hasClass('new_answer_group')) {
      currentIndex = $($currentBlock.find('[data-progress-index]')).data('progress-index');
    } else {
      currentIndex = $currentBlock.data('progress-index');
    }
    const progress = (currentIndex / total) * 100;
    const width = `${progress}%`;
    this.surveyProgress.css('width', width);

    if (progress === 100 && !this.submittedAll) {
      this.submitAllQuestionGroups();
    }
  },

  updateButtonText() {
    $('.survey__next-text').text('Next');
    $('.survey__next-text').last().text('Submit Survey');
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
      // const divisions = $(slider).data('divisions');
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
          values: 2,
          density: max,
          format: wNumb(numberFormatting)
        },
        connect: 'lower'
      });

      const $slider = $(slider);
      const $handle = $($slider.find('.noUi-handle'));
      // $handle.text(0);


      const updateValue = (value) => {
        const val = parseInt(value[0]);
        $handle.attr('data-content', val);
        $input.val(val).trigger('change');
      };

      const throttled = _throttle(updateValue, 100);

      slider.noUiSlider.on('update', throttled);


      // slider.noUiSlider.on('change', (value) => {
      //
      // });

      // $input.on('change', ({ target }) => {
      //   slider.noUiSlider.set(target.value);
      // });
    });
  },

  initConditionals() {
    $('[data-conditional-question]').each((i, question) => {
      const $conditionalQuestion = $(question);
      let $question = $($(question).parents(BLOCK_CONTAINER_SELECTOR));
      const conditionalOptions = Utils.parseConditionalString($conditionalQuestion.data('conditional-question'));
      const { question_id, value } = conditionalOptions;

      if ($question.find('.survey__question--matrix').length) {
        this.detachedParentBlocks[$question.data('block-index')] = $question;
        $question.detach();
        $question = $conditionalQuestion;
        $question.addClass('hidden');
      } else {
        $question.detach();
      }

      this.addConditionalQuestionToStore(question_id, $question);
      this.addListenersToConditional($question, conditionalOptions);
      this.surveyConditionals[question_id].currentAnswers = [];

      if (typeof value === 'undefined' && value === null) return;

      const $currentQuestionValue = this.surveyConditionals[question_id][value];
      if ($currentQuestionValue) {
        const $newQuestionSet = $currentQuestionValue.add($question);
        this.surveyConditionals[question_id][value] = $newQuestionSet;
      } else {
        this.surveyConditionals[question_id][value] = $question;
      }
    });
  },

  addConditionalQuestionToStore(questionId, $question) {
    if (typeof this.surveyConditionals[questionId] !== 'undefined') {
      this.surveyConditionals[questionId].children.push($question[0]);
    } else {
      this.surveyConditionals[questionId] = {};
      this.surveyConditionals[questionId].children = [$question[0]];
    }
  },

  addListenersToConditional($question, conditionalOptions) {
    const {
      question_id, operator, value, multi
    } = conditionalOptions;
    switch (operator) {
      case '*presence':
        return this.conditionalPresenceListeners(question_id, $question);
      case '<': case '>': case '<=': case '>=':
        return this.conditionalComparisonListeners(question_id, operator, value, $question);
      default:
        return this.conditionalAnswerListeners(question_id, multi);
    }
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

      // this.indexBlocks();
    });
  },

  handleParentConditionalChange(value, conditionalGroup, $parent) {
    let { currentAnswers } = conditionalGroup;
    let conditional;
    // let resetQuestions = false;

    if (Array.isArray(value)) {
      // Check if empty
      if (value.length === 0 && currentAnswers) {
        conditionalGroup.currentAnswers = [];
      }

      // Check if conditional was present and is no longer
      currentAnswers.forEach((a) => {
        if (value.indexOf(a) === -1) {
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
        if (conditionalGroup[v] !== undefined &&
            currentAnswers.indexOf(v) === -1) {
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
    $question.find('input[type=text], textarea').val('');
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
      this.indexBlocks();
    }
    this.updateButtonText();
  },

  attachMatrixParentBlock($question, questionGroupIndex) {
    const $parent = $question.parents(BLOCK_CONTAINER_SELECTOR);
    const $parentBlock = this.detachedParentBlocks[$parent.data('block-index')];
    // If parent node is currently detached, re-add it to the question_group slider
    if (!$.contains(document, $parentBlock)) {
      const parentIndex = $parentBlock[0].dataset.blockIndex;
      const $slider = this.groupSliders[questionGroupIndex];
      $slider.slick('slickAdd', $parentBlock, (parentIndex - 1));
      this.indexBlocks();
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
  },

  // renderMarkdown() {
  //   $('[data-render-markdown]').each((i, el) => {
  //     const $el = $(el);
  //     const markdownSrc = $el.data('render-markdown');
  //     $el.html(markdown.render(markdownSrc));
  //   });
  // },
  getNotificationId() {
    this.surveyNotificationId = $('[data-notification]').data('notification');
  }
};


export default Survey;
