import React, { useEffect, useState } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import { Cookies } from 'react-cookie-consent';
import NotesList from './notes_list';
import NotesCreator from './notes_creator';
import NotesModalTrigger from './notes_modal_trigger';
import { useFetchAllAdminCourseNotesQuery, useCreateAdminCourseNoteMutation, sendNotification } from '../../slices/AdminCourseNotesSlice';

const NotesPanel = ({ current_user }) => {
  // State variables for managing the modal and note creation
  const [isModalOpen, setIsModalOpen] = useState(null);
  const [isNoteCreationActive, setIsNoteCreationActive] = useState(false);

  // State Variables to store current value note during creation
  const [noteTitle, setTitle] = useState('');
  const [noteText, setText] = useState('');

  // State for the live message when the admin panel modal opens
  const [liveMessage, setLiveMessage] = useState('');

  // Get the current course from the Redux store
  const course = useSelector(state => state.course);

  // Get the dispatch function from the Redux store
  const dispatch = useDispatch();

  // Hook to Fetch all admin course notes for the current course
  const { data: fetchedAdminNotes } = useFetchAllAdminCourseNotesQuery(course.id);

  // Hook to trigger the note creation mutation and track its success state
  const [addNewAdminNote, { isSuccess: noteCreationSuccess, reset: resetNoteCreationState }] = useCreateAdminCourseNoteMutation();

  if (noteCreationSuccess) {
    setIsNoteCreationActive(false);
    setText('');
    setTitle('');
    // Set the cookie timestamp after note creation to prevent the admin from receiving redundant notifications for notes they’ve created
    setNoteFetchTimestamp();
    // Resets the note creation mutation state after a successful creation
    resetNoteCreationState();
  }

  // Updates the cookie timestamp to track when notes were last fetched or created.
  function setNoteFetchTimestamp() {
    // Set the current timestamp as a cookie when the user fetches notes or create notes
    const currentTimestamp = Date.now();

    // Set the expiration date to 10 years from now
    const expires = new Date();
    expires.setFullYear(expires.getFullYear() + 10);

    Cookies.set('lastFetchAdminNoteTimestamp', currentTimestamp, { expires });
  }

  // Handle opening and closing the modal with the Escape key and manage the live region message For SR
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
      setLiveMessage(I18n.t('notes.admin.aria_label.notes_panel_opened'));
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

  // Handle posting a new note
  const onClickPostNotesHandler = (courseId) => {
    const adminCourseNoteDetails = { text: noteText, title: noteTitle, courses_id: courseId, edited_by: current_user.username };

    if ((adminCourseNoteDetails.title.trim().length === 0) || (adminCourseNoteDetails.text.trim().length === 0)) {
      return sendNotification(dispatch, 'Error', 'notes.empty_fields');
    }

    addNewAdminNote(adminCourseNoteDetails);
  };

  // Close the modal and deactivate note creation
  const closeModalAndHandleNoteCreation = () => {
    setIsModalOpen(null);
    setIsNoteCreationActive(false);
  };

  // Conditionally render a button if modalType is null
  if (!isModalOpen) {
    return (
      <NotesModalTrigger
        setIsModalOpen={setIsModalOpen}
        notesList={fetchedAdminNotes?.AdminCourseNotes || []}
        setNoteFetchTimestamp={setNoteFetchTimestamp}
      />
    );
  }

  return (
    <>
      <div className="basic-modal">
        {/* Add a close button to the modal */}
        <button
          onClick={closeModalAndHandleNoteCreation}
          aria-label={I18n.t('notes.admin.aria_label.close_admin')}
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
                aria-label={I18n.t('notes.admin.aria_label.create_note')}
              >
                <span className="icon admin-note-create-icon" aria-hidden="true" />
                <span className="tooltip create--admin--note" aria-hidden="true">
                  <p>{I18n.t('notes.create_note')}</p>
                </span>
              </button>
            )}

            {/* Add cancel and post buttons for the note creation process */}
            {isNoteCreationActive && (
              <div role="group" aria-label={I18n.t('notes.admin.aria_label.note_action_button')}>
                <button
                  className="tooltip-trigger cancel--note admin-focus-highlight"
                  onClick={() => setIsNoteCreationActive(false)}
                  aria-label={I18n.t('notes.admin.aria_label.cancel_note_creation')}
                >
                  <span className="icon admin-note-cancel-icon" aria-hidden="true" />
                  <span className="tooltip cancel--note">
                    <p>{I18n.t('notes.cancel_note_creation')}</p>
                  </span>
                </button>
                <button
                  className="tooltip-trigger post--note admin-focus-highlight"
                  onClick={() => onClickPostNotesHandler(course.id)}
                  aria-label={I18n.t('notes.admin.aria_label.post_created_note')}
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
          <NotesList
            notesList={fetchedAdminNotes?.AdminCourseNotes || []}
            current_user={current_user}
            setNoteFetchTimestamp={setNoteFetchTimestamp}
          />
        </div>

        {/* Announcement for screen readers */}
        <div aria-live="assertive" aria-atomic="true" className="sr-admin-note-only">
          {liveMessage}
        </div>
      </div>
    </>
  );
};

export default NotesPanel;
