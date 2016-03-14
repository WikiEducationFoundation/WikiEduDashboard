Utils =
  parseConditionalString: (string) ->
    params = string.split '|'
    return {} =
      question_id : params[0]
      operator : params[1]
      value : params[2]

module.exports = Utils