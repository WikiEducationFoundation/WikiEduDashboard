Utils =
  parseConditionalString: (string) ->
    params = string.split '|'
    return {} =
      question_id : params[0]
      operator : params[1]
      value : params[2].trim().split(' ').join('_')
      multi : if params[3]? and params[3] is 'multi' then true else false

  toTitleCase: (str) ->
    str.replace /\w\S*/g, (txt) ->
      return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase()

module.exports = Utils
