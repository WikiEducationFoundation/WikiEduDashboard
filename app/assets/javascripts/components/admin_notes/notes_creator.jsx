import React, { useEffect, useState } from 'react';
import TextAreaInput from '../common/text_area_input.jsx';

const NotesCreator = ({ noteTitle, setTitle, noteText, setText }) => {
  const [liveMessage, setLiveMessage] = useState('');

  useEffect(() => {
    // Announce that the note creation area is available when the component mounts for screen reader
    setLiveMessage(I18n.t('notes.admin.aria_label.note_creation'));
  }, []);

  const updateNoteText = (_valueKey, value) => {
    setText(value);
  };

  const updateNoteTitle = (_valueKey, value) => {
    setTitle(value);
  };

  // handleFocus for keyboard accessibility and screen reader support
  const handleFocus = (field) => {
    const message = field === 'note_text'
      ? I18n.t('notes.admin.aria_label.note_text_field')
      : I18n.t('notes.admin.aria_label.note_title_field');
    setLiveMessage(message);
  };

  const textAreaInputComponent = (onChange, placeHolder, key) => (
    <TextAreaInput
      onChange = {onChange}
      value = {key === 'note_text' ? noteText : noteTitle}
      placeholder = {placeHolder}
      value_key = {key}
      editable = {true}
      markdown = {true}
      autoExpand = {true}
      onFocus = {() => handleFocus(key)} // Announce on focus
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
      {/* Aria-live region for screen reader announcements */}
      <div aria-live="assertive" aria-atomic="true" className="sr-admin-note-only">
        {liveMessage}
      </div>
    </div>
  );
};

export default NotesCreator;
