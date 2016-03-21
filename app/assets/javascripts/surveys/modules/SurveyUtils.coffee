Utils =
  parseConditionalString: (string) ->
    params = string.split '|'
    return {} =
      question_id : params[0]
      operator : params[1]
      value : params[2]
      multi : if params[3]? and params[3] is 'multi' then true else false

module.exports = Utils