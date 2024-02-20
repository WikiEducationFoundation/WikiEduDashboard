import persistedCourseNoteReducer from '../../app/assets/javascripts/reducers/persisted_course_note';
import * as types from '../../app/assets/javascripts/constants';

describe('persistedCourseNote reducer', () => {
  it('should handle RECEIVE_NOTE_DETAILS', () => {
    const initialState = {};
    const noteDetails = { id: 1, title: 'Received Title', text: 'Received Text' };

    const action = { type: types.RECEIVE_NOTE_DETAILS, note: noteDetails };
    expect(persistedCourseNoteReducer(initialState, action)).toEqual(noteDetails);
  });

  it('should handle PERSISTED_COURSE_NOTE', () => {
    const initialState = {};
    const persistedNote = { id: 2, title: 'Persisted Title', text: 'Persisted Text' };

    const action = { type: types.PERSISTED_COURSE_NOTE, note: persistedNote };
    expect(persistedCourseNoteReducer(initialState, action)).toEqual(persistedNote);
  });

  it('should handle RESET_NOTE_TO_DEFAULT', () => {
    const currentState = { id: 3, title: 'Current Title', text: 'Current Text' };

    const action = { type: types.RESET_NOTE_TO_DEFAULT };
    expect(persistedCourseNoteReducer(currentState, action)).toEqual({});
  });
});
