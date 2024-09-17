import React from 'react';
import TextAreaInput from '../common/text_area_input.jsx';

const NotesCreator = ({ noteTitle, setTitle, noteText, setText }) => {
  const updateNoteText = (_valueKey, value) => {
    setText(value);
  };

  const updateNoteTitle = (_valueKey, value) => {
    setTitle(value);
  };

  const textAreaInputComponent = (onChange, placeHolder, key) => (
    <TextAreaInput
      onChange = {onChange}
      value = {key === 'note_text' ? noteText : noteTitle}
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
