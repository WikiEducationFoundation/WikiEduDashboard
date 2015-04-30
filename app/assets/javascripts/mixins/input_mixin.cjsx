InputMixin =
  onChange: (e) ->
    if e.target.value != this.props.value
      this.props.onChange this.props.value_key, e.target.value

module.exports = InputMixin
