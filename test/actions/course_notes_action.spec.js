import thunk from 'redux-thunk';
import configureMockStore from 'redux-mock-store';
import logErrorMessage from '../../app/assets/javascripts/utils/log_error_message';
import * as actions from '../../app/assets/javascripts/actions/course_notes_action';
import * as types from '../../app/assets/javascripts/constants/notes';
import * as api from '../../app/assets/javascripts/utils/api';
import { ADD_NOTIFICATION } from '../../app/assets/javascripts/constants';

const middlewares = [thunk];
const mockStore = configureMockStore(middlewares);

jest.mock('../../app/assets/javascripts/utils/api', () => ({
  fetchAllCourseNotes: jest.fn(),
  updateCourseNote: jest.fn(),
  createCourseNote: jest.fn(),
  deleteCourseNote: jest.fn(),
}));

jest.mock('../../app/assets/javascripts/utils/log_error_message', () => jest.fn());

describe('Course Notes Actions', () => {
  let store;

  beforeEach(() => {
    store = mockStore({});
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should dispatch RECEIVE_NOTES_LIST after successfully fetching all course notes', async () => {
    const courseId = 'some-course-id';
    const notesList = [{ id: 1, title: 'Note 1' }];

    api.fetchAllCourseNotes.mockResolvedValue(notesList);

    await store.dispatch(actions.fetchAllCourseNotes(courseId));

    expect(store.getActions()).toEqual([{ type: types.RECEIVE_NOTES_LIST, notes_list: notesList }]);
  });

  it('should log an error if there is an issue fetching all course notes', async () => {
    const courseId = 'some-course-id';

    api.fetchAllCourseNotes.mockRejectedValue(new Error('Some error'));

    await store.dispatch(actions.fetchAllCourseNotes(courseId));

    expect(logErrorMessage).toHaveBeenCalledWith('Error fetching course notes:', expect.any(Error));
  });

  it('should dispatch RECEIVE_NOTE_DETAILS after successfully fetching a single course note', async () => {
    const courseNoteId = 1;
    const noteDetails = { id: 1, title: 'Note 1' };
    const state = { courseNotes: { notes_list: [noteDetails] } };

    store = mockStore(state);

    await store.dispatch(actions.currentNoteEdit(courseNoteId));

    expect(store.getActions()).toEqual([{ type: types.RECEIVE_NOTE_DETAILS, note: noteDetails }]);
  });

  it('should log an error if there is an issue fetching a single course note', async () => {
    const courseNoteId = 'some-note-id';
    const state = { courseNotes: { notes_list: [] } };

    store = mockStore(state);

    const errorMessage = 'Some error message';
    const error = new Error(errorMessage);

    try {
      await store.dispatch(actions.currentNoteEdit(courseNoteId));
    } catch (err) {
      expect(err).toEqual(error);
      expect(logErrorMessage).toHaveBeenCalledWith('Error fetching single course note details:', error);
    }
  });

  it('should dispatch UPDATE_CURRENT_NOTE with the updated note data', () => {
    const data = { id: 1, title: 'Updated Title' };

    store.dispatch(actions.updateCurrentEditedCourseNote(data));

    const expectedAction = { type: types.UPDATE_CURRENT_NOTE, note: data };
    expect(store.getActions()).toEqual([expectedAction]);
  });

  it('should dispatch UPDATE_NOTES_LIST with the updated notes list', async () => {
    const noteId = 1;
    const updatedNote = { id: 1, title: 'Updated Title', text: 'Updated Text' };
    const notesList = [{ id: 1, title: 'Old Title', text: 'Old Text' }];
    const state = {
      courseNotes: {
        note: updatedNote,
        notes_list: notesList,
      },
    };

    store = mockStore(state);

    const successResponse = {
      success: true,
      course_note: {
        edited_by: 'CurrentUser',
        updated_at: '2023-05-01T12:00:00Z',
      },
    };

    api.updateCourseNote.mockResolvedValue(successResponse);

    await store.dispatch(actions.saveUpdatedCourseNote(noteId));

    const expectedUpdatedNotesList = [
      {
        id: 1,
        title: 'Updated Title',
        text: 'Updated Text',
        edited_by: 'CurrentUser',
        updated_at: '2023-05-01T12:00:00Z',
      },
    ];

    const expectedActions = [
      { type: ADD_NOTIFICATION, notification: expect.any(Object) },
      { type: types.UPDATE_NOTES_LIST, updatedNotesList: expectedUpdatedNotesList },
    ];

    expect(store.getActions()).toEqual(expectedActions);
  });

  it('should dispatch error notification when updating a course note with empty fields', async () => {
    const noteId = 1;
    const state = {
      courseNotes: {
        note: {
          id: null,
          title: '',
          text: '',
        },
      },
    };

    store = mockStore(state);

    await store.dispatch(actions.saveUpdatedCourseNote(noteId));

    const expectedActions = [
      { type: ADD_NOTIFICATION, notification: expect.any(Object) },
    ];

    expect(store.getActions()).toEqual(expectedActions);
  });

  it('should dispatch success actions when creating a course note is successful', async () => {
    const courseId = 'some-course-id';
    const courseNoteDetails = {
      title: 'Note #1',
      text: 'Soon to be updated ...',
      edited_by: 'CurrentUser',
    };
    const noteDetails = {
      id: 52,
      courses_id: 10001,
      created_at: '2024-01-19T13:32:38.850Z',
      updated_at: '2024-01-21T13:32:26.736Z',
      ...courseNoteDetails,
    };

    const state = {
      courseNotes: {
        note: courseNoteDetails,
      },
    };

    store = mockStore(state);

    api.createCourseNote.mockResolvedValue(noteDetails);

    await store.dispatch(actions.createCourseNote(courseId));

    const expectedActions = [
      { type: ADD_NOTIFICATION, notification: expect.any(Object) },
      { type: types.ADD_NEW_NOTE_TO_LIST, newNote: noteDetails },
    ];

    expect(store.getActions()).toEqual(expectedActions);
  });

  it('should dispatch error notification when creating a course note with empty fields', async () => {
    const courseId = 'some-course-id';
    const state = {
      courseNotes: {
        note: {
          title: '',
          text: '',
        },
      },
    };

    store = mockStore(state);

    await store.dispatch(actions.createCourseNote(courseId));

    const expectedActions = [
      { type: ADD_NOTIFICATION, notification: expect.any(Object) },
    ];

    expect(store.getActions()).toEqual(expectedActions);
  });


  it('dispatches success actions when delete is successful', async () => {
    const noteId = 123;
    const successResponse = { success: true };

    api.deleteCourseNote.mockResolvedValue(successResponse);

    await store.dispatch(actions.deleteNoteFromList(noteId));

    expect(api.deleteCourseNote).toHaveBeenCalledWith(noteId);
    expect(store.getActions()).toEqual([
      { type: ADD_NOTIFICATION, notification: expect.any(Object) },
      { type: types.DELETE_NOTE_FROM_LIST, deletedNoteId: noteId },
    ]);
  });

  it('dispatches error notification when delete fails', async () => {
    const noteId = 123;
    const errorResponse = { success: false };

    api.deleteCourseNote.mockResolvedValue(errorResponse);

    await store.dispatch(actions.deleteNoteFromList(noteId));

    expect(api.deleteCourseNote).toHaveBeenCalledWith(noteId);
    expect(store.getActions()).toEqual([
      { type: ADD_NOTIFICATION, notification: expect.any(Object) },
    ]);
  });

  it('dispatches RESET_NOTE_TO_DEFAULT action', () => {
    store.dispatch(actions.resetStateToDefault());

    expect(store.getActions()).toEqual([
      { type: types.RESET_NOTE_TO_DEFAULT },
    ]);
  });
});
