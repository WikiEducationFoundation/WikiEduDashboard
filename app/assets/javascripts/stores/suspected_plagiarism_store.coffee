McFly       = require 'mcfly'
Flux        = new McFly()

_revisions = []

setRevisions = (data) ->
  SuspectedPlagiarismStore.empty()
  data.revisions.map (revision) -> _revisions.push(revision)
  SuspectedPlagiarismStore.emitChange()

SuspectedPlagiarismStore = Flux.createStore
  empty: ->
    _revisions.length = 0
  getRevisions: ->
    return _revisions
, (payload) ->
  data = payload.data
  switch(payload.actionType)
    when 'RECEIVE_SUSPECTED_PLAGIARISM'
      setRevisions data
      break


module.exports = SuspectedPlagiarismStore
