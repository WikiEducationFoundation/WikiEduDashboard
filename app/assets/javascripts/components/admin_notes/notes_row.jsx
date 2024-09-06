import React, { useState, useEffect } from 'react';
import { useDispatch } from 'react-redux';
import { deleteAdminNoteFromList, saveUpdatedAdminCourseNote } from '../../actions/admin_course_notes_action';
import { initiateConfirm } from '../../actions/confirm_actions';
import { format, toDate, parseISO } from 'date-fns';
import TextAreaInput from '../common/text_area_input';

const NotesRow = ({ notesList }) => {
  // State variables to keep track of the currently edited note and the note with expanded text
  const [editNoteId, setEditNoteId] = useState(null);
  const [showNoteTextId, setShowNoteTextId] = useState(null);
  const [noteText, setNoteText] = useState('');
  const [noteTitle, setNoteTitle] = useState('');

  // State for the live message when the admin panel modal opens
  const [liveMessage, setLiveMessage] = useState('');

  const dispatch = useDispatch();

  // Function to handle note deletion
  const deleteNote = (noteId) => {
    const onConfirmDelete = () => {
      dispatch(deleteAdminNoteFromList(noteId));
    };
    const confirmMessage = I18n.t('notes.delete_note_confirmation');
    dispatch(initiateConfirm({ confirmMessage, onConfirm: onConfirmDelete }));
  };

  // Function to update the note text
  const updateNoteText = (_, value) => {
    setNoteText(value);
  };

  // Function to update the note title
  const updateNoteTitle = (_, value) => {
    setNoteTitle(value);
  };

  // Function to handle clicking on a table row
  const onNotesTableRowClickHandler = (noteId) => {
    if (noteId !== showNoteTextId) {
      setShowNoteTextId(noteId);
      setEditNoteId(null);
    } else {
      setShowNoteTextId(null);
      setEditNoteId(null);
    }
  };

  // Function to handle clicking on the edit note button
  const onNotesEditButtonClickHandler = (noteId, title, text) => {
    setEditNoteId(noteId);
    setShowNoteTextId(noteId);
    setNoteTitle(title);
    setNoteText(text);
  };

  // Function to handle clicking on the save note button
  const onNotesEditSaveButtonClickHandler = (noteId) => {
    dispatch(saveUpdatedAdminCourseNote({ id: noteId, title: noteTitle, text: noteText }));
    setEditNoteId(null);
  };

  // Function to handle clicking on the cancel note button
  const onNotesEditCancelButtonClickHandler = () => {
     setEditNoteId(null);
  };

  // Handles Enter key to toggle note expansion in the table row
  const handleKeyDown = (event, noteId) => {
    if (event.key === 'Enter' && event.target.tagName === 'TR') {
      event.preventDefault(); // Prevent the default action to avoid unintended scrolling
      onNotesTableRowClickHandler(noteId);
    }
  };

  useEffect(() => {
    if (editNoteId) {
      setLiveMessage(I18n.t('notes.admin.aria_label.note_edit_mode', { title: noteTitle }));
    }
  }, [editNoteId]);

  // Render a table row for each note
  return (
    <>
      {notesList.map((note) => {
        const isEditing = note.id === editNoteId;
        const isShowingText = note.id === showNoteTextId;
        const rowClassName = isShowingText ? 'row--border' : '';

        // Render the edit button or cancel button based on the editing state
        const notesEditButton = !isEditing ? (
          <button
            className="tooltip-trigger admin-focus-highlight"
            aria-label={I18n.t('notes.admin.aria_label.note_edit_button_focused', { title: note.title })}
            onClick={() => onNotesEditButtonClickHandler(note.id, note.title, note.text)}
          >
            <span className="icon admin-note-edit-icon"/>
            <span className="tooltip new">
              <p>{I18n.t('notes.edit_note')}</p>
            </span>
          </button>
        ) : (
          <button
            className="tooltip-trigger cancel--note admin-focus-highlight"
            aria-label={I18n.t('notes.admin.aria_label.note_edit_cancel_button_focused', { title: note.title })}
            onClick={() => onNotesEditCancelButtonClickHandler()}
          >
            <span className="icon admin-note-cancel-icon" />
            <div className="tooltip cancel--note">
              <p>{I18n.t('notes.cancel_edit_note')}</p>
            </div>
          </button>
        );

        // Render the save button
        const notesEditSaveButton = (
          <button
            className="tooltip-trigger post--note admin-focus-highlight"
            onClick={() => onNotesEditSaveButtonClickHandler(note.id)}
            aria-label={I18n.t('notes.admin.aria_label.note_edit_save_button_focused', { title: noteTitle })}
          >
            <span className="icon admin-note-post-icon" />
            <div className="tooltip post--note">
              <p>{I18n.t('notes.save_note')}</p>
            </div>
          </button>
        );

        return (
          <React.Fragment key={note.id}>
            <tr
              className="students table__admin-note__row"
              onClick={() => onNotesTableRowClickHandler(note.id)}
              onKeyDown={e => handleKeyDown(e, note.id)}
              tabIndex="0"
              aria-label={isShowingText
                ? I18n.t('notes.admin.aria_label.collapse_note', { title: note.title })
                : I18n.t('notes.admin.aria_label.expand_note', { title: note.title })}
            >
              <td className={rowClassName} onClick={e => (isEditing ? e.stopPropagation() : null)}>
                <TextAreaInput
                  onChange={updateNoteTitle}
                  value={isEditing ? noteTitle : note.title}
                  placeholder={'Note Title'}
                  valueKey={'key'}
                  editable={isEditing}
                  markdown
                  autoExpand
                />
              </td>
              <td className={rowClassName}>{note.edited_by}</td>
              <td className={rowClassName}>
                {format(toDate(parseISO(note.updated_at)), 'PPPP p')}
              </td>
              <td className={`${rowClassName} admin-note__edit`} onClick={e => e.stopPropagation()}>
                {notesEditButton}
              </td>
              <td className={`${rowClassName} admin-note__delete`} onClick={e => e.stopPropagation()}>
                {!isEditing ? (
                  <button
                    className="tooltip-trigger admin-focus-highlight"
                    aria-label={I18n.t('notes.admin.aria_label.note_delete_button_focused', { title: note.title })}
                    onClick={() => deleteNote(note.id)}
                  >
                    <span className="icon admin-note-delete-icon" />
                    <span className="tooltip new">
                      <p>{I18n.t('notes.delete_note')}</p>
                    </span>
                  </button>
                ) : (
                  notesEditSaveButton
                )}
              </td>
            </tr>
            {isShowingText && (
              <tr
                className="table__admin-note__th"
                tabIndex="0"
                aria-label={I18n.t('notes.admin.aria_label.note_details_focused', { title: note.title })}
              >
                <th colSpan="5" tabIndex="0">
                  <TextAreaInput
                    onChange={updateNoteText}
                    value={isEditing ? noteText : note.text}
                    placeholder={'Note Text'}
                    valueKey={'key'}
                    editable={isEditing}
                    markdown
                    autoExpand
                  />
                </th>
              </tr>
            )}
          </React.Fragment>
        );
      })}

      {/* Announcement for screen readers */}
      <tr className="sr-only">
        <td>
          <div aria-live="assertive" aria-atomic="true">
            {liveMessage}
          </div>
        </td>
      </tr>
    </>
  );
};

export default NotesRow;
