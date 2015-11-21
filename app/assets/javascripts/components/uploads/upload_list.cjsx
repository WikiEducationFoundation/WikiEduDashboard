React         = require 'react'
Editable      = require '../high_order/editable'

List          = require '../common/list'
Upload        = require './upload'
UploadStore   = require '../../stores/upload_store'
ServerActions = require '../../actions/server_actions'

getState = ->
  uploads: UploadStore.getModels()

UploadList = React.createClass(
  displayName: 'UploadList'
  render: ->
    elements = @props.uploads.map (upload) =>
      <Upload upload={upload} key={upload.id} {...@props} />

    keys =
      'image':
        'label': 'Image'
        'desktop_only': false
      'file_name':
        'label': 'File Name'
        'desktop_only': true
      'uploaded_by':
        'label': 'Uploaded By'
        'desktop_only': true
      'usage_count':
        'label': 'Usages'
        'desktop_only': true
      'date':
        'label': 'Date/Time'
        'desktop_only': true
        'info_key': 'uploads.time_doc'

    <List
      elements={elements}
      keys={keys}
      table_key='uploads'
      store={UploadStore}
    />
)

module.exports = Editable(UploadList, [UploadStore], ServerActions.saveUploads, getState)
