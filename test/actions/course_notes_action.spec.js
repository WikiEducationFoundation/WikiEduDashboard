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
  fetchCourseNotesById: jest.fn(),
  saveCourseNote: jest.fn(),
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
    const courseNoteId = 'some-note-id';
    const noteDetails = { id: 1, title: 'Note 1' };

    api.fetchCourseNotesById.mockResolvedValue(noteDetails);

    await store.dispatch(actions.fetchSingleNoteDetails(courseNoteId));

    expect(store.getActions()).toEqual([{ type: types.RECEIVE_NOTE_DETAILS, note: noteDetails }]);
  });

  it('should log an error if there is an issue fetching a single course note', async () => {
    const courseNoteId = 'some-note-id';

    const errorMessage = 'Some error message';
    api.fetchCourseNotesById.mockRejectedValue(new Error(errorMessage));

    await store.dispatch(actions.fetchSingleNoteDetails(courseNoteId));

    expect(logErrorMessage).toHaveBeenCalledWith('Error fetching single course note details:', expect.any(Error));
  });

  it('should dispatch UPDATE_CURRENT_NOTE with the updated note data', () => {
    const data = { id: 1, title: 'Updated Title' };

    store.dispatch(actions.updateCurrentCourseNote(data));

    const expectedAction = { type: types.UPDATE_CURRENT_NOTE, note: data };
    expect(store.getActions()).toEqual([expectedAction]);
  });

  it('should dispatch RESET_TO_ORIGINAL_NOTE with the persistedCourseNote from the state', () => {
    const getStateMock = jest.fn(() => ({ persistedCourseNote: {} }));

    const storeWithState = mockStore({}, getStateMock);

    storeWithState.dispatch(actions.resetCourseNote());

    const expectedAction = { type: types.RESET_TO_ORIGINAL_NOTE, note: {} };
    expect(storeWithState.getActions()).toEqual([expectedAction]);
  });

  it('should dispatch success actions when saving course note is successful', async () => {
    const courseNoteDetails = {
      title: 'Note #1',
      text: 'Soon to be updated ...',
      edited_by: 'CurrentUser',
      id: 52,
      courses_id: 10001,
      created_at: '2024-01-19T13:32:38.850Z',
      updated_at: '2024-01-21T13:32:26.736Z'
    };

    api.saveCourseNote.mockResolvedValue({ success: true });

    await actions.saveCourseNote(courseNoteDetails, store.dispatch);

    expect(store.getActions()).toEqual([
      { type: ADD_NOTIFICATION, notification: expect.any(Object) },
      { type: types.PERSISTED_COURSE_NOTE, note: courseNoteDetails },
    ]);

    expect(logErrorMessage).not.toHaveBeenCalled();
  });

  it('should dispatch success actions when creating a course note is successful', async () => {
    const courseId = 'some-course-id';
    const courseNoteDetails = {
      title: 'Note #1',
      text: 'Soon to be updated ...',
      edited_by: 'CurrentUser',
      id: 52,
      courses_id: 10001,
      created_at: '2024-01-19T13:32:38.850Z',
      updated_at: '2024-01-21T13:32:26.736Z'
    };
    const noteDetails = { id: 1, title: 'Note 1' };

    api.createCourseNote.mockResolvedValue(noteDetails);

    await actions.createCourseNote(courseId, courseNoteDetails, store.dispatch);

    expect(store.getActions()).toEqual([
      { type: ADD_NOTIFICATION, notification: expect.any(Object) },
      { type: types.ADD_NEW_NOTE_TO_LIST, newNote: noteDetails },
      { type: types.PERSISTED_COURSE_NOTE, note: noteDetails },
    ]);
  });

  it('should dispatch error action when persisting a course note with empty fields', async () => {
    store = mockStore({
      courseNotes: {
        note: {
          id: null,
          title: '',
          text: '',
        },
      },
    });

    await store.dispatch(actions.persistCourseNote(null, 'CurrentUser'));

    expect(store.getActions()).toEqual([
      { type: ADD_NOTIFICATION, notification: expect.any(Object) },
    ]);
  });

  it('should dispatch success action when persisting a course note with id', async () => {
    const noteDetails = {
          id: 21,
          title: 'note title',
          text: 'note text',
    };

    store = mockStore({
      courseNotes: {
        note: {
          ...noteDetails
        },
      },
    });


    await store.dispatch(actions.persistCourseNote(null, 'CurrentUser'));

    expect(store.getActions()).toEqual([
      { type: ADD_NOTIFICATION, notification: expect.any(Object) },
      { type: types.PERSISTED_COURSE_NOTE, note: noteDetails }
    ]);
  });

  it('should dispatch success actions when creating a course note is successful', async () => {
    const noteDetails = {
      courses_id: 1001,
      created_at: '2024-01-31T06:01:31.406Z',
      edited_by: 'CurrentUser',
      id: 64,
      text: 'Note text #1',
      title: 'Note title #1',
      updated_at: '2024-01-31T06:01:31.406Z'
    };

    store = mockStore({
      courseNotes: {
        note: {
          title: 'Note title #1',
          text: 'Note text #1',
          edited_by: 'CurrentUser'
        },
      },
    });


    jest.spyOn(api, 'createCourseNote').mockResolvedValue(noteDetails);

    await (actions.createCourseNote('1001', noteDetails, store.dispatch));

    expect(store.getActions()).toEqual([
      { type: ADD_NOTIFICATION, notification: expect.any(Object) },
      { type: types.ADD_NEW_NOTE_TO_LIST, newNote: noteDetails },
      { type: types.PERSISTED_COURSE_NOTE, note: noteDetails }
    ]);
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

  it('dispatches error actions when delete fails', async () => {
    const noteId = 123;
    const errorResponse = { success: false };

    api.deleteCourseNote.mockResolvedValue(errorResponse);

    await store.dispatch(actions.deleteNoteFromList(noteId));

    expect(api.deleteCourseNote).toHaveBeenCalledWith(noteId);
    expect(store.getActions()).toEqual([
      { type: ADD_NOTIFICATION, notification: expect.any(Object) },
    ]);
  });

  it('dispatches RESET_TO_DEFAULT action', () => {
    store.dispatch(actions.resetStateToDefault());

    expect(store.getActions()).toEqual([
      { type: types.RESET_NOTE_TO_DEFAULT },
    ]);
  });
});


