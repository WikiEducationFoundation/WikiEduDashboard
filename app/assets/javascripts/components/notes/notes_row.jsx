import React from 'react';
import { format, toDate, parseISO } from 'date-fns';

const NotesRow = ({ setState, notesList }) => {
  return notesList.map((note) => {
      return (
        <tr key={note.id} onClick={() => { setState(note.id, 'NoteEditor'); }} className="students">
          <td style={{ minWidth: '250px' }}>
            <div className="name">
              {note.title}
            </div>
          </td>
          <td>
            {note.edited_by}
          </td>
          <td >
            {format(toDate(parseISO(note.updated_at)), 'PPPP p')}
          </td>
        </tr>
      );
    });
};

export default NotesRow;


