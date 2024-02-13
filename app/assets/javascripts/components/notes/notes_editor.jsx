import React, { useEffect } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import { fetchSingleNoteDetails, updateCurrentCourseNote, resetStateToDefault } from '../../actions/course_notes_action';
import EditableRedux from '../high_order/editable_redux';
import TextAreaInput from '../common/text_area_input.jsx';

const NotesEditor = ({ controls, editable, toggleEditable, setState, note_id, current_user }) => {
  const notes = useSelector(state => state.courseNotes.note);
  const dispatch = useDispatch();

  useEffect(() => {
    // If note_id is provided, display the note of the given id, otherwise, the admin wants to create a new note
    if (note_id) {
      dispatch(fetchSingleNoteDetails(note_id));
    } else {
    // Clear the current state to prepare for the creation of a new note,
    // and update the name of the admin for the new note. Finally, toggle to editable mode.
      dispatch(resetStateToDefault());
      dispatch(updateCurrentCourseNote({ edited_by: current_user.username }));
      toggleEditable();
    }
  }, []);

  const updateNoteText = (_valueKey, value) => {
    dispatch(updateCurrentCourseNote({ text: value }));
  };

  const updateNoteTitle = (_valueKey, value) => {
    dispatch(updateCurrentCourseNote({ title: value }));
  };

  const textAreaInputComponent = (onChange, noteDetail, placeHolder, key) => (
    <TextAreaInput
      onChange = {onChange}
      value = {noteDetail}
      placeholder = {placeHolder}
      value_key = {key}
      editable={editable}
      markdown = {true}
      autoExpand = {true}
    />
  );


  return (
    <div className="basic-modal admin-note">
      <button onClick={() => { setState(); }} className="pull-right article-viewer-button icon-close" />
      <div className="course_main container">
        <div className="module course-description">
          <div className="section-header admin-header">
            <h2 className="note-title">{textAreaInputComponent(updateNoteTitle, notes.title, I18n.t('notes.note_title'), 'note_title', false)}</h2>
            {controls()}
          </div>
          <div className="module__data note-text">
            {textAreaInputComponent(updateNoteText, notes.text, I18n.t('notes.note_text'), 'note_text', false)}
          </div>
        </div>
      </div>
    </div>
  );
};

export default EditableRedux(NotesEditor, ('Edit Note'));
