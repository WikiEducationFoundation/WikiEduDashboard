ValidationStore = require '../stores/validation_store'
ValidationActions = require '../actions/validation_actions'

# This needs to be implemented as a mixin for state reasons.
# If there's a good way for high-order components to set state on
# children like this then let's use it.

InputMixin =
  mixins: [ValidationStore.mixin]
  storeDidChange: ->
    @setState invalid: !ValidationStore.getValidation(@props.value_key)
  onChange: (e) ->
    if e.target.value != @state.value
      @setState value: e.target.value, ->
        @props.onChange @props.value_key, @state.value

        # Validation
        if @props.required || @props.validation
          filled = @state.value.length > 0
          charcheck = (new RegExp(@props.validation)).test(@state.value)
          if @props.required && !filled
            ValidationActions.setInvalid @props.value_key, 'This field is required'
          else if @props.validation && !charcheck
            ValidationActions.setInvalid @props.value_key, 'This field has invalid characters'
          else
            ValidationActions.setValid @props.value_key
  componentWillReceiveProps: (props) ->
    @setState value: props.value, ->
      valid = ValidationStore.getValidation(@props.value_key)
      if valid && @props.required && props.value.length == 0
        ValidationActions.initialize @props.value_key, 'This field is required'
  focus: (e) ->
    $(@refs.input.getDOMNode()).closest('.block').attr('draggable', false)
  blur: (e) ->
    $(@refs.input.getDOMNode()).closest('.block').attr('draggable', true)

module.exports = InputMixin
