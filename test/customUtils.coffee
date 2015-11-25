CustomUtils =
  then: (callback, timeout) ->
    timeout = if timeout > 0 then timeout else 0
    setTimeout(callback, timeout)

module.exports = CustomUtils
