import React, { useEffect, useState } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import { fetchAllAdminCourseNotes, createAdminCourseNote } from '../../actions/admin_course_notes_action';
import NotesList from './notes_list';
import NotesCreator from './notes_creator';

const NotesPanel = () => {
  // State variables for managing the modal and note creation
  const [isModalOpen, setIsModalOpen] = useState(null);
  const [isNoteCreationActive, setIsNoteCreationActive] = useState(false);

  // State Variables to store current value note during creation or update/Edit
  const [noteTitle, setTitle] = useState('');
  const [noteText, setText] = useState('');

  // Get the list of course notes and the current course from the Redux store
  const notesList = useSelector(state => state.adminCourseNotes.notes_list);
  const course = useSelector(state => state.course);

  // Get the dispatch function from the Redux store
  const dispatch = useDispatch();

  // Fetch all course notes when the component mounts
  useEffect(() => {
    // Define a function to fetch the course notes
    const fetchData = () => {
      dispatch(fetchAllAdminCourseNotes(course.id));
    };

    // Fetch the data and set up a polling interval to fetch data periodically (every 60 seconds)
    fetchData();
    const pollInterval = setInterval(fetchData, 60000);

    // Clean up the polling interval when the component unmounts
    return () => clearInterval(pollInterval);
  }, []);

  const onClickPostNotesHandler = (courseId) => {
    setIsNoteCreationActive(false);
    dispatch(createAdminCourseNote(courseId, { text: noteText, title: noteTitle }));
    setText('');
    setTitle('');
  };

  // Conditionally render a button if modalType is null
  if (!isModalOpen) {
    return <button onClick={() => setIsModalOpen('adminNotePanel')} className="button">{I18n.t('notes.admin.button_text')}</button>;
  }

  return (
    <div className="basic-modal">
      {/* Add a close button to the modal */}
      <button onClick={() => setIsModalOpen(null)} className="pull-right article-viewer-button icon-close" />

      <div className="list__wrapper">
        <div className="section-header">
          <h3>{I18n.t('notes.admin.header_text')}</h3>

          {/* Render the "Create Note" functionality */}
          { !isNoteCreationActive && (
            <div className="tooltip-trigger admin--note--creator">
              <span className="icon admin-note-create-icon" onClick={() => setIsNoteCreationActive(true)}/>
              <div className="tooltip create--admin--note">
                <p>{I18n.t('notes.create_note')}</p>
              </div>
            </div>
          )}

          {/* Add cancel and post buttons for the note creation process */}
          { isNoteCreationActive && (
            <div>
              <span className="tooltip-trigger cancel--note">
                <span className="icon  admin-note-cancel-icon" onClick={() => setIsNoteCreationActive(false)}/>
                <div className="tooltip cancel--note">
                  <p>{I18n.t('notes.cancel_note_creation')}</p>
                </div>
              </span>
              <span className="tooltip-trigger post--note">
                <span
                  className="icon admin-note-post-icon"
                  onClick={() => onClickPostNotesHandler(course.id)}
                />
                <div className="tooltip post--note">
                  <p>{I18n.t('notes.post_note')}</p>
                </div>
              </span>
            </div>
          )}
        </div>

        {/* Render the note creation form if the isNoteCreationActive flag is true */}
        {isNoteCreationActive && <NotesCreator noteTitle={noteTitle} setTitle={setTitle} noteText={noteText} setText={setText}/>}

        {/* Render the list of course notes */}
        <NotesList notesList={notesList} />
      </div>
    </div>
   );
};

export default NotesPanel;
