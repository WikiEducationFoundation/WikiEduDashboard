import _ from 'lodash';
import {
  RECEIVE_TRAINING_MODULE, MENU_TOGGLE, SET_SELECTED_ANSWER,
  SET_CURRENT_SLIDE, RECEIVE_ALL_TRAINING_MODULES,
  SLIDE_COMPLETED, MODULE_COMPLETED
} from '../constants';

const setSelectedAnswer = function (state, answer) {
  const answerId = parseInt(answer);
  const temp = { ...state, currentSlide: { ...state.currentSlide, selectedAnswer: answerId } };
  if (state.currentSlide.assessment.correct_answer_id === answerId) {
    return { ...temp, currentSlide: { ...temp.currentSlide, answeredCorrectly: true } };
  }
  return { ...temp, currentSlide: { ...temp.currentSlide, answeredCorrectly: false } };
};

const setCurrentSlide = function (state, slideId) {
  if (!state.module.slides) { return state.currentSlide; }
  const slideIndex = _.findIndex(state.module.slides, slide => slide.slug === slideId);
  return { ...state, currentSlide: { ...state.module.slides[slideIndex] }, loading: false };
};

const setEnabledSlides = function (state, slide) {
  if (slide) {
    return { ...state, enabledSlides: [...state.enabledSlides, slide.id] };
  }
  return state;
};

const redirectTo = data => window.location = `/training/${data.library_id}/${data.module_id}`;

const getCurrentSlide = (state) => {
  return state.currentSlide;
};

const isFirstSlide = (state) => {
  return (state.currentSlide && state.currentSlide.index === 1);
};

const getPreviousSlide = (state) => {
  return getSlideRelativeToCurrent(state, { position: 'previous' });
};
const getNextSlide = (state) => {
  return getSlideRelativeToCurrent(state, { position: 'next' });
};

const getSlideRelativeToCurrent = (state, opts) => {
  if (!getCurrentSlide(state) || desiredSlideIsCurrentSlide(opts, getCurrentSlide(state), state.module.slides)) { return; }
  const slideIndex = _.findIndex(state.module.slides, slide => slide.slug === getCurrentSlide(state).slug);
  const newIndex = opts.position === 'next' ? slideIndex + 1 : slideIndex - 1;
  if (!state.module.slides) { return; }
  return state.module.slides[newIndex];
};

const desiredSlideIsCurrentSlide = (opts, currentSlide, slides) => {
  if (!slides || !slides.length) { return; }
  return (opts.position === 'next' && currentSlide.id === slides.length) || (opts.position === 'previous' && currentSlide.id === 1);
};

const initialState = {
  modules: [],
  module: {},
  slides: [],
  currentSlide: {
    id: null,
    title: '',
    content: ''
  },
  previousSlide: {},
  nextSlide: {},
  menuIsOpen: false,
  enabledSlides: [],
  loading: true,
  isFirstSlide: false
};

export default function training(state = initialState, action) {
  let newState = {};
  const data = action.data;
  switch (action.type) {
    case RECEIVE_TRAINING_MODULE: {
      const temp = { ...state, module: data.training_module };
      newState = setCurrentSlide(temp, data.slide);
      break;
    }
    case MENU_TOGGLE:
      newState = { ...state, menuIsOpen: !data.currently };
      break;
    case SET_SELECTED_ANSWER:
      newState = setSelectedAnswer(state, data.answer);
      break;
    case SET_CURRENT_SLIDE:
      newState = setCurrentSlide(state, data.slide);
      break;
    case RECEIVE_ALL_TRAINING_MODULES:
      newState = { ...state, modules: data.training_modules };
      break;
    case SLIDE_COMPLETED:
      newState = setEnabledSlides(state, data.slide);
      break;
    case MODULE_COMPLETED:
      redirectTo(data);
      break;
    default:
      newState = state;
  }
  return {
    ...newState,
    previousSlide: getPreviousSlide(newState),
    nextSlide: getNextSlide(newState),
    isFirstSlide: isFirstSlide(newState),
    slides: newState.module.slides
  };
}
