import React, { useEffect, useState } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import { fetchAllAdminCourseNotes, createAdminCourseNote } from '../../actions/admin_course_notes_action';
import NotesList from './notes_list';
import NotesCreator from './notes_creator';

const NotesPanel = () => {
  // State variables for managing the modal and note creation
  const [isModalOpen, setIsModalOpen] = useState(null);
  const [isNoteCreationActive, setIsNoteCreationActive] = useState(false);

  // State Variables to store current value note during creation
  const [noteTitle, setTitle] = useState('');
  const [noteText, setText] = useState('');

  // State for the live message when the admin panel modal opens
  const [liveMessage, setLiveMessage] = useState('');

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

  // Handle opening and closing the modal with the Escape key and manage the live region message
  useEffect(() => {
    const handleEscape = (event) => {
      if (event.key === 'Escape') {
        // Close the modal and note creation when the Escape key is pressed
        setIsModalOpen(false);
        setIsNoteCreationActive(false);
      }
    };

    if (isModalOpen) {
      // Announce modal opening for screen readers
      setLiveMessage(I18n.t('notes.screen_reader.notes_panel_opened'));
      // Listen for the Escape key press
      document.addEventListener('keydown', handleEscape);
    } else {
      // Clear the live region message when the modal is closed
      setLiveMessage('');
    }

    return () => {
      // Clean up the event listener on component unmount
      document.removeEventListener('keydown', handleEscape);
    };
  }, [isModalOpen]);

  // Handle posting a new note and reset note creation state based on the result
  const onClickPostNotesHandler = async (courseId) => {
    setIsNoteCreationActive(false);

    const status = await dispatch(createAdminCourseNote(courseId, { text: noteText, title: noteTitle }));

    if (status === 'error') {
      return setIsNoteCreationActive(true);
    }

    setText('');
    setTitle('');
  };

  // Close the modal and deactivate note creation
  const closeModalAndHandleNoteCreation = () => {
    setIsModalOpen(null);
    setIsNoteCreationActive(false);
  };

  // Conditionally render a button if modalType is null
  if (!isModalOpen) {
    return (
      <button
        onClick={() => setIsModalOpen('adminNotePanel')}
        className="button admin-focus-highlight"
        aria-haspopup="dialog"
      >
        {I18n.t('notes.admin.button_text')}
      </button>
    );
  }

  return (
    <>
      <div className="basic-modal">
        {/* Add a close button to the modal */}
        <button
          onClick={closeModalAndHandleNoteCreation}
          aria-label={I18n.t('notes.screen_reader.close_admin')}
          className="pull-right article-viewer-button icon-close admin-focus-highlight"
        />

        <div className="list__wrapper">
          <div className="section-header">
            <h3 aria-hidden="true">{I18n.t('notes.admin.header_text')}</h3>

            {/* Render the "Create Note" functionality */}
            {!isNoteCreationActive && (
              <button
                className="tooltip-trigger admin--note--creator admin-focus-highlight"
                onClick={() => setIsNoteCreationActive(true)}
                aria-label={I18n.t('notes.screen_reader.create_note')}
              >
                <span className="icon admin-note-create-icon" aria-hidden="true" />
                <span className="tooltip create--admin--note" aria-hidden="true">
                  <p>{I18n.t('notes.create_note')}</p>
                </span>
              </button>
            )}

            {/* Add cancel and post buttons for the note creation process */}
            {isNoteCreationActive && (
              <div role="group" aria-label={I18n.t('notes.screen_reader.note_action_button')}>
                <button
                  className="tooltip-trigger cancel--note admin-focus-highlight"
                  onClick={() => setIsNoteCreationActive(false)}
                  aria-label={I18n.t('notes.screen_reader.cancel_note_creation')}
                >
                  <span className="icon admin-note-cancel-icon" aria-hidden="true" />
                  <span className="tooltip cancel--note">
                    <p>{I18n.t('notes.cancel_note_creation')}</p>
                  </span>
                </button>
                <button
                  className="tooltip-trigger post--note admin-focus-highlight"
                  onClick={() => onClickPostNotesHandler(course.id)}
                  aria-label={I18n.t('notes.screen_reader.post_created_note')}
                >
                  <span
                    className="icon admin-note-post-icon"
                    aria-hidden="true"
                  />
                  <span className="tooltip post--note">
                    <p>{I18n.t('notes.post_note')}</p>
                  </span>
                </button>
              </div>
            )}
          </div>

          {/* Render the note creation form if the isNoteCreationActive flag is true */}
          {isNoteCreationActive && <NotesCreator noteTitle={noteTitle} setTitle={setTitle} noteText={noteText} setText={setText} />}

          {/* Render the list of course notes */}
          <NotesList notesList={notesList} />
        </div>

        {/* Announcement for screen readers */}
        <div aria-live="assertive" aria-atomic="true" className="sr-only">
          {liveMessage}
        </div>
      </div>
    </>
  );
};

export default NotesPanel;
