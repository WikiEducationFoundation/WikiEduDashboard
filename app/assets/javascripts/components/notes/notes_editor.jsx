import React, { useEffect } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import { fetchSingleNoteDetails, updateCurrentCourseNote, resetStateToDefault } from '../../actions/course_notes_action';
import EditableRedux from '../high_order/editable_redux';
import TextAreaInput from '../common/text_area_input.jsx';

const NotesEditor = ({ controls, editable, toggleEditable, setState, note_id, current_user }) => {
  const notes = useSelector(state => state.courseNotes.note);
  const dispatch = useDispatch();

  useEffect(() => {
    if (note_id) {
      dispatch(fetchSingleNoteDetails(note_id));
    } else {
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
            <h3 className="note-title">{textAreaInputComponent(updateNoteTitle, notes.title, I18n.t('notes.note_title'), 'note_title', false)}</h3>
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
