import React, { useState } from 'react';
import { useDispatch } from 'react-redux';
import { deleteAdminNoteFromList, updateCurrentEditedAdminCourseNote, currentAdminNoteEdit, resetStateToDefault, saveUpdatedAdminCourseNote } from '../../actions/admin_course_notes_action';
import { initiateConfirm } from '../../actions/confirm_actions';
import { format, toDate, parseISO } from 'date-fns';
import TextAreaInput from '../common/text_area_input';

const NotesRow = ({ notesList }) => {
  // State variables to keep track of the currently edited note and the note with expanded text
  const [editNoteId, setEditNoteId] = useState(null);
  const [showNoteTextId, setShowNoteTextId] = useState(null);

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
    dispatch(updateCurrentEditedAdminCourseNote({ text: value }));
  };

  // Function to update the note title
  const updateNoteTitle = (_, value) => {
    dispatch(updateCurrentEditedAdminCourseNote({ title: value }));
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

  // Function to handle clicking on the edit button
  const onNotesEditButtonClickHandler = (noteId) => {
    setEditNoteId(noteId);
    setShowNoteTextId(noteId);
    dispatch(resetStateToDefault());
    dispatch(currentAdminNoteEdit(noteId));
  };

  // Function to handle clicking on the save button
  const onNotesEditSaveButtonClickHandler = (noteId) => {
    dispatch(saveUpdatedAdminCourseNote(noteId));
    setEditNoteId(null);
  };

  // Function to handle clicking on the cancel button
  const onNotesEditCancelButtonClickHandler = () => {
     setEditNoteId(null);
     dispatch(resetStateToDefault());
  };

  // Render a table row for each note
  return notesList.map((note) => {
    const isEditing = note.id === editNoteId;
    const isShowingText = note.id === showNoteTextId;
    const rowClassName = isShowingText ? 'row--border' : '';

    // Render the edit button or cancel button based on the editing state
    const notesEditButton = !isEditing ? (
      <span className="tooltip-trigger">
        <span className="icon admin-note-edit-icon" onClick={() => onNotesEditButtonClickHandler(note.id)}/>
        <span className="tooltip new">
          <p>{I18n.t('notes.edit_note')}</p>
        </span>
      </span>
    ) : (
      <span className="tooltip-trigger cancel--note">
        <span className="icon admin-note-cancel-icon" onClick={() => onNotesEditCancelButtonClickHandler()}/>
        <div className="tooltip cancel--note">
          <p>{I18n.t('notes.cancel_edit_note')}</p>
        </div>
      </span>
    );

    // Render the save button
    const notesEditSaveButton = (
      <span className="tooltip-trigger post--note">
        <span className="icon admin-note-post-icon" onClick={() => onNotesEditSaveButtonClickHandler(note.id)}/>
        <div className="tooltip post--note">
          <p>{I18n.t('notes.save_note')}</p>
        </div>
      </span>
    );

    return (
      <React.Fragment key={note.id}>
        <tr className="students table__admin-note__row" onClick={() => onNotesTableRowClickHandler(note.id)}>
          <td className={rowClassName} onClick={e => (isEditing ? e.stopPropagation() : null)}>
            <TextAreaInput
              onChange={updateNoteTitle}
              value={note.title}
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
              <span className="tooltip-trigger">
                <span className="icon admin-note-delete-icon" onClick={() => deleteNote(note.id)}/>
                <span className="tooltip new">
                  <p>{I18n.t('notes.delete_note')}</p>
                </span>
              </span>
            ) : (
              notesEditSaveButton
            )}
          </td>
        </tr>
        {isShowingText && (
          <tr className="table__admin-note__th">
            <th colSpan="5">
              <TextAreaInput
                onChange={updateNoteText}
                value={note.text}
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
  });
};

export default NotesRow;
