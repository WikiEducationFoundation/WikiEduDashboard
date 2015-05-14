ModalMixin =
  componentWillMount: ->
    $('body').addClass('modal-open')
  componentWillUnmount: ->
    $('body').removeClass('modal-open')

module.exports = ModalMixin