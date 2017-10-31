import McFly from 'mcfly';
const Flux = new McFly();
import _ from 'lodash';

let _modules = [];
let _module = {};
let _menuState = false;
const _enabledSlides = [];
let _currentSlide = {
  id: null,
  title: '',
  content: ''
};
let _isLoading = true;

const setModule = function (trainingModule) {
  _module = trainingModule;
  return TrainingStore.emitChange();
};

const setAllModules = function (modules) {
  _modules = modules;
  return TrainingStore.emitChange();
};

const setMenuState = function (currently) {
  _menuState = !currently;
  return TrainingStore.emitChange();
};

const setSelectedAnswer = function (answer) {
  const answerId = parseInt(answer);
  _currentSlide.selectedAnswer = answerId;
  if (_currentSlide.assessment.correct_answer_id === answerId) {
    _currentSlide.answeredCorrectly = true;
  }
  return TrainingStore.emitChange();
};

const setCurrentSlide = function (slideId) {
  if (!_module.slides) { return _currentSlide; }
  const slideIndex = _.findIndex(_module.slides, slide => slide.slug === slideId);
  _currentSlide = _module.slides[slideIndex];
  _isLoading = false;
  return TrainingStore.emitChange();
};

const setEnabledSlides = function (slide) {
  if (slide) {
    _enabledSlides.push(slide.id);
  }
  return TrainingStore.emitChange();
};

const redirectTo = data => window.location = `/training/${data.library_id}/${data.module_id}`;

const storeMethods = {
  getState() {
    return {
      slides: _module.slides,
      currentSlide: _currentSlide,
      previousSlide: this.getPreviousSlide(),
      nextSlide: this.getNextSlide(),
      menuIsOpen: _menuState,
      enabledSlides: _enabledSlides,
      loading: this.getLoadingStatus(),
      isFirstSlide: this.isFirstSlide()
    };
  },
  getLoadingStatus() {
    return _isLoading;
  },
  isFirstSlide() {
    return (_currentSlide && _currentSlide.index === 1);
  },
  getTrainingModule() {
    return _module;
  },
  getAllModules() {
    return _modules;
  },
  getCurrentSlide() {
    return _currentSlide;
  },
  getSelectedAnswer() {
    const currentSlide = this.getCurrentSlide;
    return currentSlide;
  },
  getPreviousSlide() {
    return this.getSlideRelativeToCurrent({ position: 'previous' });
  },
  getNextSlide() {
    return this.getSlideRelativeToCurrent({ position: 'next' });
  },
  getSlideRelativeToCurrent(opts) {
    if (!this.getCurrentSlide() || this.desiredSlideIsCurrentSlide(opts, this.getCurrentSlide(), _module.slides)) { return; }
    const slideIndex = _.findIndex(_module.slides, slide => slide.slug === this.getCurrentSlide().slug);
    const newIndex = opts.position === 'next' ? slideIndex + 1 : slideIndex - 1;
    if (!_module.slides) { return; }
    return _module.slides[newIndex];
  },
  desiredSlideIsCurrentSlide(opts, currentSlide, slides) {
    if (!slides || !slides.length) { return; }
    return (opts.position === 'next' && currentSlide.id === slides.length) || (opts.position === 'previous' && currentSlide.id === 1);
  },
  restore() {
    return false;
  }
};

const TrainingStore = Flux.createStore(storeMethods, (payload) => {
  const { data } = payload;
  switch (payload.actionType) {
    case 'RECEIVE_TRAINING_MODULE':
      setModule(data.training_module);
      return setCurrentSlide(data.slide);
    case 'MENU_TOGGLE':
      return setMenuState(data.currently);
    case 'SET_SELECTED_ANSWER':
      return setSelectedAnswer(data.answer);
    case 'SET_CURRENT_SLIDE':
      return setCurrentSlide(data.slide);
    case 'RECEIVE_ALL_TRAINING_MODULES':
      return setAllModules(data.training_modules);
    case 'SLIDE_COMPLETED':
      return setEnabledSlides(data.slide);
    case 'MODULE_COMPLETED':
      return redirectTo(data);
    default:
      // no default
  }
});

export default TrainingStore;
