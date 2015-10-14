React             = require 'react'
ServerActions = require '../actions/server_actions'
BlockStore = require '../stores/block_store'
TrainingStore = require '../training/stores/training_store'
BlockActions = require '../actions/block_actions'
md              = require('markdown-it')({ html: true, linkify: true })

getState = ->
  module: TrainingStore.getTrainingModule()
  all_modules: TrainingStore.getAllModules()

TrainingBlock = React.createClass(
  displayName: 'TrainingBlock'
  mixins: [BlockStore.mixin, TrainingStore.mixin]
  storeDidChange: ->
    @setState getState()
  getInitialState: ->
    module: { name: '' }
    all_modules: []
  componentWillMount: ->
    ServerActions.fetchTrainingModuleForBlock(@props.block.id)
    ServerActions.fetchAllTrainingModules()
  componentWillReceiveProps: (newProps) ->
    ServerActions.fetchTrainingModuleById(newProps.block.training_module_id)
  render: ->
    if @props.editable
      modules = _.compact(@state.all_modules).map (module) -> (
        <option id={module.id} value={module.id}>{module.name}</option>
      )
      selectVal = @state.module.id?.toString()
      content = (
        <label className="select_wrapper" id="training_module_select">
          Module Name:&nbsp;
          <select id="module_select" ref="module_select" value={selectVal} onChange={@props.onChange}>
            {modules}
          </select>
        </label>
      )
    else
      if @state.module.name
        link = "/training/students/#{@state.module.slug}"
        raw_html = md.render(@state.module.intro)
        content = (
          <div>
            <p>{@state.module.name}</p>
            <div dangerouslySetInnerHTML={{__html: raw_html}}></div>
            <hr />
            <p><a href={link}>Go to training</a></p>
          </div>
        )

    <div>
     {content}
    </div>

)

module.exports = TrainingBlock
