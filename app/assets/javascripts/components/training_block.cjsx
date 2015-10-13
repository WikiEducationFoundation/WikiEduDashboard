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
    <h3>{@state.module.name}</h3>

)

module.exports = TrainingBlock
