import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import { Cookies } from 'react-cookie-consent';

const NotesModalTrigger = ({ setIsModalOpen, notesList, setNoteFetchTimestamp }) => {
  const [notificationCount, setNotificationCount] = useState(0);

  const onClickAdminButton = () => {
    setIsModalOpen('adminNotePanel');
    setNotificationCount(0);
    setNoteFetchTimestamp();
  };

  useEffect(() => {
    // Retrieve the last fetch timestamp from the cookie
    const userLastFetchTimestamp = Cookies.get('lastFetchAdminNoteTimestamp');

    // Check if the cookie value is a valid number
    const parsedTimestamp = isFinite(userLastFetchTimestamp) ? parseInt(userLastFetchTimestamp) : 0;

    // Calculate the count of new notes
    const newAdminNoteCount = notesList.filter(note => new Date(note.updated_at) > new Date(parsedTimestamp)).length;

    // Update the notification count state
    setNotificationCount(newAdminNoteCount);
  }, [notesList]);

  // Accessible message for screen readers, indicating whether there are new admin notes or none available
  const notesAriaLabel = !notesList.length
    ? I18n.t('notes.admin.aria_label.no_notes_available')
    : I18n.t('notes.admin.aria_label.new_notes_message', { count: notificationCount });

  return (
    <div className="admin-notes-modal-trigger">
      <button
        onClick={onClickAdminButton}
        className="button admin-focus-highlight admin-action-button"
        aria-haspopup="dialog"
        aria-label={notesAriaLabel}
      >
        {I18n.t('notes.admin.button_text')}
      </button>
      {
        (notificationCount > 0) && (
        <div className="icon-notification_admin--badge">
          {notificationCount}
        </div>
      )}
    </div>
  );
};

// Define PropTypes
NotesModalTrigger.propTypes = {
  setIsModalOpen: PropTypes.func.isRequired, // Expecting a function, required
  setNoteFetchTimestamp: PropTypes.func.isRequired,
  notesList: PropTypes.arrayOf(PropTypes.object).isRequired // Expecting an array of objects, required
};

export default NotesModalTrigger;
