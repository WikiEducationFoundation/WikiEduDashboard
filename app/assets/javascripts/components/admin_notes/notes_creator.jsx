import React from 'react';
import { useDispatch } from 'react-redux';
import { updateCurrentEditedAdminCourseNote } from '../../actions/admin_course_notes_action';
import TextAreaInput from '../common/text_area_input.jsx';

const NotesCreator = () => {
  const dispatch = useDispatch();

  const updateNoteText = (_valueKey, value) => {
    dispatch(updateCurrentEditedAdminCourseNote({ text: value }));
  };

  const updateNoteTitle = (_valueKey, value) => {
    dispatch(updateCurrentEditedAdminCourseNote({ title: value }));
  };

  const textAreaInputComponent = (onChange, placeHolder, key) => (
    <TextAreaInput
      onChange = {onChange}
      value = {''}
      placeholder = {placeHolder}
      value_key = {key}
      editable={true}
      markdown = {true}
      autoExpand = {true}
    />
  );

  return (
    <div className="admin-note-creator">
      <div className="module course-description">
        <div className="section-header">
          <h2 className="admin-note-creator__title">{textAreaInputComponent(updateNoteTitle, I18n.t('notes.note_title'), 'note_title')}</h2>
        </div>
        <div className="module__data">
          {textAreaInputComponent(updateNoteText, I18n.t('notes.note_text'), 'note_text')}
        </div>
      </div>
    </div>
  );
};

export default (NotesCreator);
