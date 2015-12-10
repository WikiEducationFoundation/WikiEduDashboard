class DateCalculator
  constructor: (@beginning, @ending, @loopIndex, @opts) ->

  startDate: ->
    index = if @opts.zeroIndexed is true then @loopIndex else @loopIndex - 1
    moment(@beginning).startOf('week').add(7 * index, 'day')

  start: ->
    @startDate().format("MM/DD")

  endDate: ->
    moment.min(@startDate().clone().add(6, 'day'), moment(@ending))

  end: ->
    @endDate().format("MM/DD")

module.exports = DateCalculator

