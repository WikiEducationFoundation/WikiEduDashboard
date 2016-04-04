React = require 'react'
TrainingStore = require '../stores/training_store.coffee'
TrainingActions = require '../actions/training_actions.coffee'
ServerActions = require '../../actions/server_actions.coffee'
ReactRouter     = require 'react-router'
History         = ReactRouter.History
Link            = ReactRouter.Link
SlideLink       = require './slide_link.cjsx'
SlideMenu       = require './slide_menu.cjsx'
Quiz            = require './quiz.cjsx'
md              = require('../../utils/markdown_it.js').default({ openLinksExternally: true })
browserHistory = ReactRouter.browserHistory

getState = ->
  return TrainingStore.getState()

TrainingSlideHandler = React.createClass(
  displayName: 'TrainingSlideHandler'
  mixins: [TrainingStore.mixin]
  getInitialState: ->
    slide: {}
    menuIsOpen: false
    currentSlide: {}
    nextSlide: {}
    previousSlide: {}
    slides: []
    loading: true
    enabledSlides: []
  moduleId: ->
    @props.params?.module_id
  componentDidMount: ->
    getState(@props)
  componentWillReceiveProps: (newProps) ->
    slide_id = newProps.params.slide_id
    TrainingActions.setCurrentSlide(slide_id)
    @setSlideCompleted(slide_id)
    @setState getState(newProps)
  componentWillMount: ->
    slide_id = @props.params?.slide_id
    ServerActions.fetchTrainingModule(module_id: @moduleId(), current_slide_id: slide_id)
    @setSlideCompleted(slide_id)
  storeDidChange: ->
    @setState getState()
  setSlideCompleted: (slide_id) ->
    user_id = document.getElementById('main')?.getAttribute('data-user-id')
    return unless user_id
    ServerActions.setSlideCompleted(
      slide_id: slide_id,
      module_id: @moduleId(),
      user_id: user_id
    )
  toggleMenuOpen: (e) ->
    e.stopPropagation()
    TrainingActions.toggleMenuOpen(currently: @state.menuIsOpen)
  closeMenu: (e) ->
    if @state.menuIsOpen
      e.stopPropagation()
      TrainingActions.toggleMenuOpen(currently: true)
  userLoggedIn: ->
    typeof document.getElementById('main')?.getAttribute('data-user-id') is 'string'

  keys: { rightKey: 39, leftKey: 37 }

  disableNext: ->
    @state.currentSlide.assessment? && !@state.currentSlide.answeredCorrectly

  trainingUrl: (params) ->
    "/training/#{params.library_id}/#{params.module_id}/#{params.slide_id}"

  handleKeyPress: (e) ->
    navParams = library_id: @props.params.library_id, module_id: @props.params.module_id
    if e.which == @keys.leftKey && @state.previousSlide?
      params = _.extend navParams, slide_id: @state.previousSlide.slug
      browserHistory.push(@trainingUrl(params))
    if e.which == @keys.rightKey && @state.nextSlide?
      return if @disableNext()
      @setSlideCompleted(@props.params.slide_id)
      params = _.extend navParams, slide_id: @state.nextSlide.slug
      browserHistory.push(@trainingUrl(params))

  componentDidMount: ->
    window.addEventListener('keyup', @handleKeyPress)

  componentWillUnmount: ->
    window.removeEventListener('keyup', @handleKeyPress)

  render: ->
    if @state.loading is true
      return (
        <div className="training-loader">
          <h1 className="h2">Loading…</h1>
          <div className="training-loader__spinner"></div>
        </div>
      )

    if @state.loading is false && !@state.currentSlide?.id
      window.location = '/errors/file_not_found'

    if @state.nextSlide?.slug
      nextLink = <SlideLink
                   slideId={@state.nextSlide.slug}
                   direction='Next'
                   disabled={@disableNext()}
                   button=true
                   params={@props.params} />
    else
      nextHref = if @userLoggedIn() then '/' else "/training/#{@props.params.library_id}"
      nextLink = <a href={nextHref} className='btn btn-primary pull-right'>Done!</a>

    if !@userLoggedIn()
      loginWarning = (
        <div className='training__slide__notification' key='not_logged_in'>
          <div className='container'>
            <p>{I18n.t("training.logged_out")}</p>
          </div>
        </div>
      )

    if @state.previousSlide?.slug
      previousLink = <SlideLink
                       slideId={@state.previousSlide.slug}
                       direction='< Previous'
                       params={@props.params} />

    if @state.currentSlide.content?
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

    if @state.currentSlide.title_prefix?
      titlePrefix = (
        <h2 className="training__slide__title-prefix">{@state.currentSlide.title_prefix}</h2>
      )

    <div>
      {loginWarning}
      <header>
        <div className="pull-right training__slide__nav" onClick={@toggleMenuOpen}>
          <div className="pull-right hamburger">
            <span className="hamburger__bar"></span>
            <span className="hamburger__bar"></span>
            <span className="hamburger__bar"></span>
          </div>
          <h3 className="pull-right">
            <a href="" onFocus={@toggleMenuOpen}>Page {@state.currentSlide.index} of {@state.slides.length}</a>
          </h3>
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
        {titlePrefix}
        <h1>{@state.currentSlide.title}</h1>
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
