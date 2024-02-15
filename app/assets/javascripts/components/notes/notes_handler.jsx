import React, { useState } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import { nameHasChanged } from '../../actions/course_actions';
import { resetCourseNote, persistCourseNote } from '../../actions/course_notes_action';
import { getCurrentUser } from '../../selectors/index';
import NotesEditor from './notes_editor';
import NotesPanel from './notes_panel';

const NotesHandler = () => {
  const [modalType, setModalType] = useState(null);
  const [noteId, setNoteId] = useState(null);
  const course = useSelector(state => state.course);
  const currentUser = useSelector(getCurrentUser);
  const dispatch = useDispatch();

  const dispatchNameHasChanged = () => {
    dispatch(nameHasChanged());
  };
  const dispatchPersistCourseNote = () => {
    dispatch(persistCourseNote(course.id, currentUser.username));
  };
  const dispatchResetCourseNote = () => {
    dispatch(resetCourseNote());
  };

  const setState = (id = null, type = 'DefaultPanel') => {
    setNoteId(id);
    setModalType(type);
  };

  const defaultAdminNotesPanel = (
    <NotesPanel
      setState={setState}
      modalType={modalType}
      currentUser={currentUser}
      courseId={course.id}
      buttonText={'notes.admin.button_text'}
      headerText={'notes.admin.header_text'}
    />
  );

  const adminNotesEditPanel = (
    <NotesEditor
      title={course.title}
      course_id={course.slug}
      current_user={currentUser}
      note_id={noteId}
      resetState={dispatchResetCourseNote}
      persistCourse={dispatchPersistCourseNote}
      nameHasChanged={dispatchNameHasChanged}
      setState={setState}
    />
  );

  switch (modalType) {
    case 'NoteEditor':
      return adminNotesEditPanel;
    default:
      return defaultAdminNotesPanel;
  }
};

export default (NotesHandler);
