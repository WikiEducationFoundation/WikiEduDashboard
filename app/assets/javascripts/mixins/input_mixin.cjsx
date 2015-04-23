InputMixin =
  save: ->
    if this.props.value != this.state.value
      this.props.onSave this.props.value_key, this.state.value
  onChange: (e) ->
    if e.target.value != this.props.value
      this.setState value: e.target.value
  getInitialState: ->
    value: this.props.value || ''
  componentWillReceiveProps: (props) ->
    this.setState(props)

module.exports = InputMixin
