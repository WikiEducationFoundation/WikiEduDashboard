React = require 'react'
TrainingStore = require '../stores/training_store'
ServerActions = require '../../actions/server_actions'

getState = ->
  training_module: TrainingStore.getTrainingModule()

TrainingModuleHandler = React.createClass(
  displayName: 'TraniningModuleHandler'
  mixins: [TrainingStore.mixin]
  getInitialState: ->
    getState()
  storeDidChange: ->
    @setState getState()
  componentWillMount: ->
    module_id = document.getElementById('react_root').dataset.moduleId
    ServerActions.fetchTrainingModule(module_id: module_id)
  render: ->
    slidesAry = _.compact(@state.training_module.slides)
    slides = slidesAry.map (slide, i) =>
      disabled = !slide.enabled
      link = "#{@state.training_module.slug}/#{slide.slug}"
      liClassName = 'disabled' if disabled
      <li className={liClassName} key={i}>
        <a disabled={disabled} href={link}>
          <h3 className="h5">{slide.title}</h3>
          <div className="ui-text small sidebar-text">{slide.summary}</div>
        </a>
      </li>

    <div className="training__toc-container">
      <h1 className="h4 capitalize">Table of Contents <span className="pull-right total-slides">({slidesAry.length})</span></h1>
      <ol>
      {slides}
      </ol>
    </div>
)

module.exports = TrainingModuleHandler

