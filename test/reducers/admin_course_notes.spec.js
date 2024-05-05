import courseNotesReducer from '../../app/assets/javascripts/reducers/admin_course_notes';
import * as types from '../../app/assets/javascripts/constants';

describe('courseNotes reducer', () => {
  const initialState = {
    notes_list: [],
    note: {
      title: '',
      text: '',
    },
  };

  it('should return the initial state', () => {
    expect(courseNotesReducer(undefined, {})).toEqual(initialState);
  });

  it('should handle RECEIVE_NOTES_LIST', () => {
    const notesList = [{ id: 1, title: 'Note 1' }];
    const action = { type: types.RECEIVE_NOTES_LIST, notes_list: notesList };

    expect(courseNotesReducer(initialState, action)).toEqual({
      ...initialState,
      notes_list: notesList,
    });
  });

  it('should handle ADD_NEW_NOTE_TO_LIST', () => {
    const newNote = { id: 2, title: 'Note 2' };
    const action = { type: types.ADD_NEW_NOTE_TO_LIST, newNote: newNote };

    expect(courseNotesReducer(initialState, action)).toEqual({
      ...initialState,
      notes_list: [...initialState.notes_list, newNote],
    });
  });

  it('should handle DELETE_NOTE_FROM_LIST', () => {
    const currentState = {
      notes_list: [
        { id: 1, title: 'Note 1' },
        { id: 2, title: 'Note 2' },
      ],
      note: initialState.note,
    };

    const action = { type: types.DELETE_NOTE_FROM_LIST, deletedNoteId: 1 };

    expect(courseNotesReducer(currentState, action)).toEqual({
      ...currentState,
      notes_list: currentState.notes_list.filter(note => note.id !== action.deletedNoteId),
    });
  });

  it('should handle RECEIVE_NOTE_DETAILS', () => {
    const currentState = {
      notes_list: [],
      note: initialState.note,
    };

    const noteDetails = { id: 1, title: 'Note 1', text: 'Note Text', edited_by: 'User' };
    const action = { type: types.RECEIVE_NOTE_DETAILS, note: noteDetails };

    expect(courseNotesReducer(currentState, action)).toEqual({
      ...currentState,
      note: { ...currentState.note, ...noteDetails },
    });
  });

  it('should handle UPDATE_CURRENT_NOTE', () => {
    const currentState = {
      notes_list: [],
      note: { title: 'Old Title', text: 'Old Text', edited_by: 'User' },
    };

    const updatedNote = { title: 'New Title', text: 'New Text' };
    const action = { type: types.UPDATE_CURRENT_NOTE, note: updatedNote };

    expect(courseNotesReducer(currentState, action)).toEqual({
      ...currentState,
      note: { ...currentState.note, ...updatedNote },
    });
  });

  it('should handle RESET_NOTE_TO_DEFAULT', () => {
    const currentState = {
      notes_list: [{ id: 1, title: 'Note 1' }],
      note: {
        title: 'Note Title',
        text: 'Note Text',
        edited_by: 'User',
      },
    };

    const action = { type: types.RESET_NOTE_TO_DEFAULT };

    expect(courseNotesReducer(currentState, action)).toEqual({
      ...currentState,
      note: initialState.note,
    });
  });
});
