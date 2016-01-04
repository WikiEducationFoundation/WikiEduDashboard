McFly = require 'mcfly'
Flux  = new McFly()

_modules = []
_module = {}
_menuState = false
_enabledSlides = []
_currentSlide = {
  id: null,
  title: '',
  content: ''
}
_isLoading = true

setModule = (trainingModule) ->
  _module = trainingModule
  TrainingStore.emitChange()

setAllModules = (modules) ->
  _modules = modules
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
  _isLoading = false
  TrainingStore.emitChange()

setEnabledSlides = (slide) ->
  _enabledSlides.push(slide.id)
  TrainingStore.emitChange()

redirectTo = (data) ->
  window.location = "/training/#{data.library_id}/#{data.module_id}"

TrainingStore = Flux.createStore
  getState: ->
    slides:        _module.slides
    currentSlide:  _currentSlide
    previousSlide: @getPreviousSlide()
    nextSlide:     @getNextSlide()
    menuIsOpen:    _menuState
    enabledSlides: _enabledSlides
    loading: @getLoadingStatus()
    isFirstSlide: @isFirstSlide()

  getLoadingStatus: ->
    return _isLoading
  isFirstSlide: ->
    _currentSlide?.index is 1
  getTrainingModule: ->
    return _module
  getAllModules: ->
    return _modules
  getCurrentSlide: ->
    return _currentSlide
  getSelectedAnswer: ->
    currentSlide = @getCurrentSlide
  getPreviousSlide: ->
    @getSlideRelativeToCurrent(position: 'previous')
  getNextSlide: ->
    @getSlideRelativeToCurrent(position: 'next')
  getSlideRelativeToCurrent: (opts) ->
    return if !@getCurrentSlide() || @desiredSlideIsCurrentSlide(opts, @getCurrentSlide(), _module.slides)
    slideIndex = _.findIndex(_module.slides, (slide) => slide.slug == @getCurrentSlide().slug)
    newIndex = if opts.position is 'next' then slideIndex + 1 else slideIndex - 1
    return unless _module.slides
    return _module.slides[newIndex]
  desiredSlideIsCurrentSlide: (opts, currentSlide, slides) ->
    return unless slides?.length
    (opts.position is 'next' && currentSlide.id == slides.length) || (opts.position is 'previous' && currentSlide.id == 1)
  restore: ->
    false
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
    when 'RECEIVE_ALL_TRAINING_MODULES'
      setAllModules data.training_modules
      break
    when 'SLIDE_COMPLETED'
      setEnabledSlides data.slide
      break
    when 'MODULE_COMPLETED'
      redirectTo data
      break

module.exports = TrainingStore
