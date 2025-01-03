import { findIndex } from 'lodash-es';
import {
  RECEIVE_TRAINING_MODULE, MENU_TOGGLE, REVIEW_ANSWER,
  SET_CURRENT_SLIDE, RECEIVE_ALL_TRAINING_MODULES,
  SLIDE_COMPLETED, SET_TRAINING_MODE
} from '../constants';

const reviewAnswer = function (state, answer) {
  const answerId = parseInt(answer);
  const temp = { ...state, currentSlide: { ...state.currentSlide, selectedAnswer: answerId } };
  if (state.currentSlide.assessment.correct_answer_id === answerId) {
    return { ...temp, currentSlide: { ...temp.currentSlide, answeredCorrectly: true } };
  }
  return { ...temp, currentSlide: { ...temp.currentSlide, answeredCorrectly: false } };
};

const setCurrentSlide = function (state, slideId) {
  if (!state.module.slides) { return state; }
  const slideIndex = findIndex(state.module.slides, slide => slide.slug === slideId);
  return { ...state, currentSlide: { ...state.module.slides[slideIndex] }, loading: false };
};

const getCurrentSlide = (state) => {
  return state.currentSlide;
};

const getPreviousSlide = (state) => {
  return getSlideRelativeToCurrent(state, { position: 'previous' });
};
const getNextSlide = (state) => {
  return getSlideRelativeToCurrent(state, { position: 'next' });
};

const getSlideRelativeToCurrent = (state, opts) => {
  if (!getCurrentSlide(state) || desiredSlideIsCurrentSlide(opts, getCurrentSlide(state), state.module.slides)) { return; }
  const slideIndex = findIndex(state.module.slides, slide => slide.slug === getCurrentSlide(state).slug);
  const newIndex = opts.position === 'next' ? slideIndex + 1 : slideIndex - 1;
  if (!state.module.slides) { return; }
  return state.module.slides[newIndex];
};

const desiredSlideIsCurrentSlide = (opts, currentSlide, slides) => {
  if (!slides || !slides.length) { return; }
  return (opts.position === 'next' && currentSlide.id === slides.length) || (opts.position === 'previous' && currentSlide.id === 1);
};

const update = (state) => {
  return {
    ...state,
    previousSlide: getPreviousSlide(state),
    nextSlide: getNextSlide(state),
    slides: state.module.slides
  };
};

const initialState = {
  libraries: [],
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
  completed: null,
  valid: false,
  editMode: false,
};

export default function training(state = initialState, action) {
  const data = action.data;
  switch (action.type) {
    case RECEIVE_TRAINING_MODULE: {
      const newState = {
        ...state,
        module: data.training_module,
        valid: data.valid
      };
      if (newState.valid) {
        return update(setCurrentSlide(newState, data.slide));
      }
      return { ...newState, loading: false };
    }
    case MENU_TOGGLE:
      return { ...state, menuIsOpen: !data.currently };
    case REVIEW_ANSWER:
      return reviewAnswer(state, data.answer);
    case SET_CURRENT_SLIDE:
      return update(setCurrentSlide(state, data.slide));
    case RECEIVE_ALL_TRAINING_MODULES:
      return { ...state, modules: data.training_modules, libraries: data.training_libraries };
    case SLIDE_COMPLETED:
      return {
        ...state,
        enabledSlides: [...state.enabledSlides, data.slide.id],
        completed: data.completed
      };
    case SET_TRAINING_MODE:
      return {
        ...state,
        editMode: data.editMode
      };
    default:
      return state;
  }
}
