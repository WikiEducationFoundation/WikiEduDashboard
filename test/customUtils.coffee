require './testHelper'

CustomUtils =
  click: (el) ->
    new Promise (resolve, reject) ->
      Simulate.click(el)
      resolve el

module.exports = CustomUtils
