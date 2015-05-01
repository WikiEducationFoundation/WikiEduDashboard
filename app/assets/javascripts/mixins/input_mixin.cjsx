InputMixin =
  onChange: (e) ->
    if e.target.value != this.state.value
      this.setState value: e.target.value, ->
        this.props.onChange this.props.value_key, this.state.value
  componentWillReceiveProps: (props) ->
    this.setState value: props.value

module.exports = InputMixin
