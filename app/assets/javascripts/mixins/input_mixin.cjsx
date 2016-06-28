ValidationStore = require '../stores/validation_store.coffee'
ValidationActions = require('../actions/validation_actions.js').default
UUID = require('node-uuid')

# This needs to be implemented as a mixin for state reasons.
# If there's a good way for high-order components to set state on
# children like this then let's use it.

InputMixin =
  mixins: [ValidationStore.mixin]

  storeDidChange: ->
    @setState invalid: !ValidationStore.getValidation(@props.value_key)

  onChange: (e) ->
    value = e.target.value
    if value != @state.value
      @setState value: value, ->
        @props.onChange @props.value_key, value
        @validate()

  validate: ->
    if @props.required || @props.validation
      filled = @state.value? && @state.value.length > 0
      if @props.validation instanceof RegExp
        charcheck = (new RegExp(@props.validation)).test(@state.value)
      else if typeof(@props.validation) == "function"
        charcheck = @props.validation(@state.value)
      if @props.required && !filled
        if _.has(@props, 'disableSave')
          @props.disableSave(true)
        ValidationActions.setInvalid @props.value_key, I18n.t('application.field_required')
      else if @props.validation && !charcheck
        invalidMessage = @props.invalidMessage || I18n.t('application.field_invalid_characters')
        ValidationActions.setInvalid @props.value_key, invalidMessage
      else
        ValidationActions.setValid @props.value_key

  componentWillReceiveProps: (props) ->
    @setState
      value: props.value,
      id: props.id or @state.id or UUID.v4() # create a UUID if no id prop
    , ->
      valid = ValidationStore.getValidation(@props.value_key)
      if valid && @props.required && (!props.value? || props.value.length == 0)
        ValidationActions.initialize @props.value_key, I18n.t('application.field_required')

  focus: (e) ->
    @props.onFocus() if @props.onFocus?

  blur: (e) ->
    @props.onBlur() if @props.onBlur?

module.exports = InputMixin
