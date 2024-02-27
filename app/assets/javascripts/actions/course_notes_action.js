import API from '../utils/api';
import logErrorMessage from '../utils/log_error_message';
import { ADD_NOTIFICATION } from '../constants/notifications';

import {
  UPDATE_CURRENT_NOTE,
  RECEIVE_NOTE_DETAILS,
  RESET_TO_ORIGINAL_NOTE,
  PERSISTED_COURSE_NOTE,
  RESET_NOTE_TO_DEFAULT,
  RECEIVE_NOTES_LIST,
  ADD_NEW_NOTE_TO_LIST,
  DELETE_NOTE_FROM_LIST
} from '../constants';

// Helper function to dispatch notifications
const sendNotification = (dispatch, type, messageKey, dynamicValue) => {
  const notificationConfig = {
    message: I18n.t(messageKey, dynamicValue),
    closable: true,
    type: type === 'Success' ? 'success' : 'error',
  };

  dispatch({
    type: ADD_NOTIFICATION,
    notification: notificationConfig,
  });
};

// Action creator to fetch all course notes for a given courseId
export const fetchAllCourseNotes = courseId => async (dispatch) => {
  try {
    const notesList = await API.fetchAllCourseNotes(courseId);
    dispatch({ type: RECEIVE_NOTES_LIST, notes_list: notesList });
  } catch (error) {
    logErrorMessage('Error fetching course notes:', error);
  }
};

// Action creator to fetch details of a single course note by its ID
export const fetchSingleNoteDetails = courseNoteId => async (dispatch) => {
  try {
    const note = await API.fetchCourseNotesById(courseNoteId);
    dispatch({ type: RECEIVE_NOTE_DETAILS, note });
  } catch (error) {
    logErrorMessage('Error fetching single course note details:', error);
  }
};

// Action creator to update the current course note with new data
export const updateCurrentCourseNote = data => (dispatch) => {
  dispatch({ type: UPDATE_CURRENT_NOTE, note: { ...data } });
};

// Action creator to reset the current course note to its original state
export const resetCourseNote = () => (dispatch, getState) => {
  const CourseNote = getState().persistedCourseNote;
  dispatch({ type: RESET_TO_ORIGINAL_NOTE, note: { ...CourseNote } });
};

// Action creator to save/update the current course note
export const saveCourseNote = async (currentUser, courseNoteDetails, dispatch) => {
  const status = await API.saveCourseNote(currentUser, courseNoteDetails);

  if (status?.success) {
    sendNotification(dispatch, 'Success', 'notes.updated');
    dispatch({ type: PERSISTED_COURSE_NOTE, note: courseNoteDetails });
  } else {
    const messageKey = 'notes.failure';
    const dynamicValue = { operation: 'update' };
    sendNotification(dispatch, 'Error', messageKey, dynamicValue);
  }
};

// Action creator to create a new course note for a given courseId
export const createCourseNote = async (courseId, courseNoteDetails, dispatch) => {
  const noteDetails = await API.createCourseNote(courseId, courseNoteDetails);

  if (noteDetails?.id) {
    sendNotification(dispatch, 'Success', 'notes.created');
    dispatch({ type: ADD_NEW_NOTE_TO_LIST, newNote: noteDetails });
    dispatch({ type: PERSISTED_COURSE_NOTE, note: noteDetails });
  } else {
    const messageKey = 'notes.failure';
    const dynamicValue = { operation: 'create' };
    sendNotification(dispatch, 'Error', messageKey, dynamicValue);
  }
};

// Action creator to persist the current course note, handling validation and deciding whether to save/update or create
export const persistCourseNote = (courseId = null, currentUser) => (dispatch, getState) => {
  const courseNoteDetails = getState().courseNotes.note;

  if ((courseNoteDetails.title.trim().length === 0) || (courseNoteDetails.text.trim().length === 0)) {
    return sendNotification(dispatch, 'Error', 'notes.empty_fields');
  } else if (courseNoteDetails.id) {
    return saveCourseNote(currentUser, courseNoteDetails, dispatch);
  }

  createCourseNote(courseId, courseNoteDetails, dispatch);
};

// Action creator to delete a course note from the list based on its ID
export const deleteNoteFromList = noteId => async (dispatch) => {
  const status = await API.deleteCourseNote(noteId);

  if (status?.success) {
    sendNotification(dispatch, 'Success', 'notes.deleted');
    dispatch({ type: DELETE_NOTE_FROM_LIST, deletedNoteId: noteId });
  } else {
    sendNotification(dispatch, 'Error', 'notes.delete_note_error');
  }
};

// Action creator to reset the state of the course note to its default values
export const resetStateToDefault = () => (dispatch) => {
  dispatch({ type: RESET_NOTE_TO_DEFAULT });
};
