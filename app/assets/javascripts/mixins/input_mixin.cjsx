# This needs to be implemented as a mixin for state reasons.
# If there's a good way for high-order components to set state on
# children like this then let's use it.

InputMixin =
  onChange: (e) ->
    if e.target.value != this.state.value
      this.setState value: e.target.value, ->
        this.props.onChange this.props.value_key, this.state.value
  componentWillReceiveProps: (props) ->
    this.setState value: props.value

module.exports = InputMixin
