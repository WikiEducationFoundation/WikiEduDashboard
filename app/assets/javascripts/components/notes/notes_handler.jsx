import React, { useState } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import { nameHasChanged } from '../../actions/course_actions';
import { resetCourseNote, persistCourseNote } from '../../actions/course_notes_action';
import NotesEditor from './notes_editor';
import NotesPanel from './notes_panel';

const NotesHandler = ({ currentUser }) => {
  const [modalType, setModalType] = useState(null);
  const [noteId, setNoteId] = useState(null);

  const course = useSelector(state => state.course);
  const dispatch = useDispatch();

  // If user is Admin and not Wiki Ed Staff, fetch Admin username from 'nav_root'.
  // If user is Admin and Wiki Ed Staff, username is already in CurrentUser.
  if (!currentUser.username) {
    const { username } = document.getElementById('nav_root').dataset;
    currentUser = { ...currentUser, username };
  }

  const dispatchNameHasChanged = () => {
    dispatch(nameHasChanged());
  };

  const dispatchPersistCourseNote = () => {
    dispatch(persistCourseNote(course.id, currentUser.username));
  };

  const dispatchResetCourseNote = () => {
    dispatch(resetCourseNote());
  };

  // Function to set the modal type and note ID based on the parameters:
  // a) If id is null and type is 'DefaultPanel', display 'NotesPanel'.
  // b) If id is null and type is 'NoteEditor', display 'CreateNewNote'.
  // c) If id is notesId and type is 'NoteEditor', display 'NoteDetails' of the current NoteId.
  const setState = (id = null, type = 'DefaultPanel') => {
    setNoteId(id);
    setModalType(type);
  };

  // If modalType is null, this will simply return a button which, on click, displays admin 'NotesPanel'
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

  // Admin notes edit panel for reading, editing/updating and creating admin notes
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

  // Switch statement to determine which panel to display based on the modalType
  switch (modalType) {
    case 'NoteEditor':
      return adminNotesEditPanel;
    default:
      return defaultAdminNotesPanel;
  }
};

export default NotesHandler;
