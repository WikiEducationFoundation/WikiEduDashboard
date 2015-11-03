React = require 'react'
TrainingStore = require '../stores/training_store'
TrainingActions = require '../actions/training_actions'
ServerActions = require '../../actions/server_actions'
Router          = require 'react-router'
Link            = Router.Link
Navigation      = Router.Navigation
SlideLink       = require './slide_link'
SlideMenu       = require './slide_menu'
Quiz            = require './quiz'
md              = require('markdown-it')({ html: true, linkify: true })

getState = ->
  return TrainingStore.getState()

TrainingSlideHandler = React.createClass(
  displayName: 'TrainingSlideHandler'
  mixins: [TrainingStore.mixin, Navigation]
  getInitialState: ->
    loading: true
  moduleId: ->
    @props.params.module_id
  componentDidMount: ->
    getState(@props)
  componentWillReceiveProps: (newProps) ->
    TrainingActions.setCurrentSlide(newProps.params.slide_id)
    @setState getState(newProps)
  componentWillMount: ->
    ServerActions.fetchTrainingModule(module_id: @moduleId(), current_slide_id: @props.params.slide_id)
  setSlideCompleted: ->
    user_id = document.getElementById('main').dataset.userId
    return unless user_id
    ServerActions.setSlideCompleted(
      slide_id: @props.params.slide_id,
      module_id: @moduleId(),
      user_id: user_id
    )
  setModuleCompleted: (e) ->
    e.preventDefault()
    user_id = document.getElementById('main').dataset.userId
    return unless user_id
    ServerActions.setModuleCompleted(
      library_id: @props.params.library_id,
      module_id: @moduleId(),
      user_id: user_id
    )
  storeDidChange: ->
    @setState getState()
  toggleMenuOpen: (e) ->
    e.stopPropagation()
    TrainingActions.toggleMenuOpen(currently: @state.menuIsOpen)
  closeMenu: (e) ->
    if @state.menuIsOpen
      e.stopPropagation()
      TrainingActions.toggleMenuOpen(currently: true)

  keys: { rightKey: 39, leftKey: 37 }

  handleKeyPress: (e) ->
    navParams = library_id: @props.params.library_id, module_id: @props.params.module_id
    if e.which == @keys.leftKey && @state.previousSlide?
      params = _.extend navParams, slide_id: @state.previousSlide.slug
      @transitionTo 'slide', params
    if e.which == @keys.rightKey && @state.nextSlide?
      @setSlideCompleted()
      params = _.extend navParams, slide_id: @state.nextSlide.slug
      @transitionTo 'slide', params

  componentDidMount: ->
    window.addEventListener('keyup', @handleKeyPress)

  componentWillUnmount: ->
    window.removeEventListener('keyup', @handleKeyPress)

  render: ->
    if @state.loading is true
      return (<h1>Loading</h1>)

    disableNext = @state.currentSlide.assessment? && !@state.currentSlide.answeredCorrectly

    if @state.nextSlide?.slug
      nextLink = <SlideLink
                   slideId={@state.nextSlide.slug}
                   direction='Next'
                   disabled={disableNext}
                   slideTitle='Next Page'
                   button=true
                   onClick={@setSlideCompleted}
                   params={@props.params} />
    else
      nextLink = <Link
                   to='module'
                   params={@props.params}
                   className='btn btn-primary pull-right'
                   onClick={@setModuleCompleted}>
                   Done!
                  </Link>

    if @state.previousSlide?.slug
      previousLink = <SlideLink
                       slideId={@state.previousSlide.slug}
                       direction='Previous'
                       slideTitle={@state.previousSlide.title}
                       params={@props.params} />

    raw_html = md.render(@state.currentSlide.content)
    menuClass = if @state.menuIsOpen is false then 'hidden' else 'shown'

    if @state.currentSlide.assessment
      assessment = @state.currentSlide.assessment
      quiz = <Quiz
        question={assessment.question}
        answers={assessment.answers}
        selectedAnswer={@state.currentSlide.selectedAnswer}
        correctAnswer={@state.currentSlide.assessment.correct_answer_id}
      />

    <div>
      <header>
        <div className="pull-right training__slide__nav" onClick={@toggleMenuOpen}>
          <div className="pull-right hamburger">
            <span className="hamburger__bar"></span>
            <span className="hamburger__bar"></span>
            <span className="hamburger__bar"></span>
          </div>
          <h3 className="pull-right">Page {@state.currentSlide.index} of {@state.slides.length}</h3>
        </div>
        <SlideMenu
          closeMenu={@closeMenu}
          onClick={@toggleMenuOpen}
          menuClass={menuClass}
          currentSlide={@state.currentSlide}
          params={@props.params}
          enabledSlides={@state.enabledSlides}
          slides={@state.slides} />
      </header>
      <article className="training__slide">
        <h1 className="h3">{@state.currentSlide.title}</h1>
        <div className='markdown training__slide__content' dangerouslySetInnerHTML={{__html: raw_html}}></div>
        {quiz}
        <footer className="training__slide__footer">
         <span className="pull-left">{previousLink}</span>
         <span  className="pull-right">{nextLink}</span>
        </footer>
      </article>
    </div>
)

module.exports = TrainingSlideHandler
