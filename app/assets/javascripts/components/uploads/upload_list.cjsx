React         = require 'react'
Editable      = require '../high_order/editable.cjsx'

List          = require '../common/list.cjsx'
Upload        = require './upload.cjsx'
UploadStore   = require '../../stores/upload_store.coffee'
ServerActions = require('../../actions/server_actions.js').default
CourseUtils   = require '../../utils/course_utils.coffee'

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
      none_message={CourseUtils.i18n('uploads_none', @props.course.string_prefix)}
      store={UploadStore}
    />
)

module.exports = Editable(UploadList, [UploadStore], ServerActions.saveUploads, getState)
