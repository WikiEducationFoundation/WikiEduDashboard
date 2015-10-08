McFly = require 'mcfly'
Flux  = new McFly()

_module = {}
_menuState = false
_selectedAnswer = null

setModule = (trainingModule) ->
  _module = trainingModule
  TrainingStore.emitChange()

setMenuState = (currently) ->
  _menuState = !currently
  TrainingStore.emitChange()

setSelectedAnswer = (answer) ->
  _selectedAnswer = parseInt(answer)
  TrainingStore.emitChange()

TrainingStore = Flux.createStore
  getMenuState: ->
    return _menuState
  getSlides: ->
    return _module.slides
  getTrainingModule: ->
    return _module
  getSelectedAnswer: ->
    return _selectedAnswer
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
    (opts.position is 'next' && currentSlide.id == slides.length) || (opts.position is 'previous' && currentSlide.id == 1)
  getCurrentSlide: (props) ->
    slides = @getSlides()
    if slides && props?.params
      return slides[_.findIndex(slides, (slide) -> slide.slug == props.params.slide_id)]
, (payload) ->
  data = payload.data
  switch(payload.actionType)
    when 'RECEIVE_TRAINING_MODULES'
      setModule data.training_module
      break
    when 'MENU_TOGGLE'
      setMenuState data.currently
      break
    when 'SET_SELECTED_ANSWER'
      setSelectedAnswer data.answer
      break

module.exports = TrainingStore
