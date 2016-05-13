React          = require 'react'
UploadList     = require './upload_list.cjsx'
AssignmentList = require '../assignments/assignment_list.cjsx'
UIActions      = require('../../actions/ui_actions.js').default
ServerActions  = require('../../actions/server_actions.js').default


UploadsHandler = React.createClass(
  displayName: 'UploadsHandler'
  sortSelect: (e) ->
    UIActions.sort 'uploads', e.target.value
  componentWillMount: ->
    ServerActions.fetch 'uploads', @props.course_id
  render: ->
    <div id='uploads'>
      <div className='section-header'>
        <h3>{I18n.t('uploads.header')}</h3>
        <div className='sort-select'>
          <select className='sorts' name='sorts' onChange={@sortSelect}>
            <option value='file_name'>{I18n.t('uploads.file_name')}</option>
            <option value='uploader'>{I18n.t('uploads.uploaded_by')}</option>
            <option value='usage_count'>{I18n.t('uploads.usage_count')}</option>
          </select>
        </div>
      </div>
      <UploadList {...@props} />
    </div>
)

module.exports = UploadsHandler
