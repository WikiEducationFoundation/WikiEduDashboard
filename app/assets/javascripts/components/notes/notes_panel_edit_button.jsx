import React from 'react';
import { useDispatch } from 'react-redux';
import { deleteNoteFromList } from '../../actions/course_notes_action';
import { initiateConfirm } from '../../actions/confirm_actions';
import useExpandablePopover from '../../hooks/useExpandablePopover';
import Popover from '../common/popover.jsx';

export const NotesPanelEditButton = ({ setState, currentUser, notesList }) => {
  const getKey = () => {
   return 'Create Notes';
  };

  const stop = (e) => {
    return e.stopPropagation();
  };

  const deleteNote = (noteId) => {
    const onConfirm = () => {
      dispatch(deleteNoteFromList(noteId));
    };
    const confirmMessage = I18n.t('notes.delete_note_confirmation');
    dispatch(initiateConfirm({ confirmMessage, onConfirm }));
  };

  const { isOpen, ref, open } = useExpandablePopover(getKey);
  const dispatch = useDispatch();
  const editRows = [];

  const notesRow = notesList.map((note) => {
    let removeButton;
    if (currentUser.admin) {
      removeButton = (
        <button className="button border plus" aria-label="Remove user" onClick={() => deleteNote(note.id)}>-</button>
      );
    }
    return (
      <tr key={`${note.id}`} >
        <td>{note.title}{removeButton}</td>
      </tr>
    );
  });

  const button = (
    <button
      className= "button dark"
      onClick={() => {
        open();
      }}
    >
      {'Edit Notes'}
    </button>
  );

  editRows.push(
    <tr className="edit" key="add_notes">
      <td className="admin-note-create">
        <button onClick={() => { setState(undefined, 'NoteEditor'); }} className="button border" >{'Create Notes'}</button>
      </td>
    </tr>
  );

  return (
    <div className="pop__container" onClick={stop} ref={ref}>
      {button}
      <Popover
        is_open={isOpen}
        edit_row={editRows}
        rows = {notesRow}
      />
    </div>
  );
};

export default NotesPanelEditButton;
