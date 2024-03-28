import React from 'react';
import List from '../common/list.jsx';
import NotesRow from './notes_row.jsx';

const NotesList = ({ setState, notesList }) => {
  const keys = {
    title: {
      label: I18n.t('notes.title'),
      desktop_only: false
    },
    revisor: {
    label: I18n.t('notes.edited_by'),
    desktop_only: true,
    info_key: 'notes.last_edited_by'
    },
    date: {
    label: 'Date/Time',
    desktop_only: true,
    info_key: 'notes.edit'
    }
  };

  let notesRow = [];

  if (notesList.length > 0) {
    notesRow = <NotesRow setState={setState} notesList={notesList} />;
  }

  return (
    <List
      elements={notesRow}
      className="table--expandable table--hoverable table--admin_note"
      keys={keys}
      table_key="revisions"
      none_message={I18n.t('notes.no_notes')}
      stickyHeader={true}
    />
  );
};

export default (NotesList);
