McFly = require 'mcfly'
Flux  = new McFly()

_module = {}
_menuState = false
_currentSlide = {
  id: null,
  title: '',
  content: ''
}

setModule = (trainingModule) ->
  _module = trainingModule
  TrainingStore.emitChange()

setMenuState = (currently) ->
  _menuState = !currently
  TrainingStore.emitChange()

setSelectedAnswer = (answer) ->
  answerId = parseInt(answer)
  _currentSlide.selectedAnswer = answerId
  if _currentSlide.assessment.correct_answer_id == answerId
    _currentSlide.answeredCorrectly = true
  TrainingStore.emitChange()

setCurrentSlide = (slide_id) ->
  return _currentSlide unless _module.slides
  slideIndex = _.findIndex(_module.slides, (slide) -> slide.slug == slide_id)
  _currentSlide = _module.slides[slideIndex]
  TrainingStore.emitChange()

TrainingStore = Flux.createStore
  getMenuState: ->
    return _menuState
  getSlides: ->
    return _module.slides
  getTrainingModule: ->
    return _module
  getCurrentSlide: ->
    return _currentSlide
  getSelectedAnswer: ->
    currentSlide = @getCurrentSlide
  getPreviousSlide: (props) ->
    @getSlideRelativeToCurrent(props, position: 'previous')
  getNextSlide: (props) ->
    @getSlideRelativeToCurrent(props, position: 'next')
  getSlideRelativeToCurrent: (props, opts) ->
    currentSlide = @getCurrentSlide(props)
    return if !currentSlide || @desiredSlideIsCurrentSlide(opts, currentSlide, _module.slides)
    slides = @getSlides()
    if slides && props?.params
      slideIndex = _.findIndex(slides, (slide) -> slide.slug == props.params.slide_id)
      newIndex = if opts.position is 'next' then slideIndex + 1 else slideIndex - 1
      return slides[newIndex]
  desiredSlideIsCurrentSlide: (opts, currentSlide, slides) ->
    return unless slides?.length
    (opts.position is 'next' && currentSlide.id == slides.length) || (opts.position is 'previous' && currentSlide.id == 1)

, (payload) ->
  data = payload.data
  switch(payload.actionType)
    when 'RECEIVE_TRAINING_MODULE'
      setModule data.training_module
      setCurrentSlide data.slide
      break
    when 'MENU_TOGGLE'
      setMenuState data.currently
      break
    when 'SET_SELECTED_ANSWER'
      setSelectedAnswer data.answer
      break
    when 'SET_CURRENT_SLIDE'
      setCurrentSlide data.slide
      break

module.exports = TrainingStore
