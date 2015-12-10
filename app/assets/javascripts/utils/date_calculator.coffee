class DateCalculator
  constructor: (@beginning, @ending, @loopIndex) ->

  startDate: ->
    moment(@beginning).startOf('week').add(7 * @loopIndex - 1, 'day')

  start: ->
    @startDate().format("MM/DD")

  endDate: ->
    moment.min(@startDate().clone().add(6, 'day'), moment(@ending))

  end: ->
    @endDate().format("MM/DD")

module.exports = DateCalculator

