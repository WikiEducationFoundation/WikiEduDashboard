# This needs to be implemented as a mixin for state reasons.
# If there's a good way for high-order components to set state on
# children like this then let's use it.

InputMixin =
  onChange: (e) ->
    if e.target.value != @state.value
      @setState value: e.target.value, ->
        @props.onChange @props.value_key, @state.value
  componentWillReceiveProps: (props) ->
    @setState value: props.value

module.exports = InputMixin
