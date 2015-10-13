React             = require 'react'
ServerActions = require '../actions/server_actions'
BlockStore = require '../stores/block_store'

getState = ->
  module: BlockStore.getTrainingModule()

TrainingBlock = React.createClass(
  displayName: 'TrainingBlock'
  mixins: [BlockStore.mixin]
  storeDidChange: ->
    @setState getState()
  getInitialState: ->
    module: {
      name: ''
    }

  componentWillMount: ->
    ServerActions.fetchTrainingModuleForBlock(@props.block.id)

  render: ->
    link = "/training/students/#{@state.module.slug}"

    <div>
      <p>{@state.module.name}</p>
      <p>{@state.module.intro}</p>
      <hr />
      <p><a href={link}>Go to training</a></p>
    </div>

)

module.exports = TrainingBlock
