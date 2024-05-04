import API from '../utils/api';
import logErrorMessage from '../utils/log_error_message';
import { ADD_NOTIFICATION } from '../constants/notifications';

import {
  UPDATE_CURRENT_NOTE,
  RECEIVE_NOTE_DETAILS,
  RESET_NOTE_TO_DEFAULT,
  RECEIVE_NOTES_LIST,
  ADD_NEW_NOTE_TO_LIST,
  DELETE_NOTE_FROM_LIST,
  UPDATE_NOTES_LIST
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

// Action creator to fetch details of a note currently being edited
export const currentNoteEdit = courseNoteId => async (dispatch, getState) => {
  const note = getState().courseNotes.notes_list.find(courseNote => courseNote.id === courseNoteId);
  try {
    dispatch({ type: RECEIVE_NOTE_DETAILS, note });
  } catch (error) {
    logErrorMessage('Error fetching single course note details:', error);
  }
};

// Action creator to update the current course note title or text with new data
export const updateCurrentEditedCourseNote = data => (dispatch) => {
  dispatch({ type: UPDATE_CURRENT_NOTE, note: { ...data } });
};

// Action creator to save the updated current course note to Database
export const saveUpdatedCourseNote = noteId => async (dispatch, getState) => {
   const courseNoteDetails = { ...getState().courseNotes.note, id: noteId };

  if ((courseNoteDetails.title.trim().length === 0) || (courseNoteDetails.text.trim().length === 0)) {
    return sendNotification(dispatch, 'Error', 'notes.empty_fields');
  }

  const status = await API.updateCourseNote(courseNoteDetails);

  if (status?.success) {
    sendNotification(dispatch, 'Success', 'notes.updated');

    const updatedNotesList = getState().courseNotes.notes_list.map((note) => {
        if (note.id === noteId) {
          return {
            ...note,
            title: getState().courseNotes.note.title,
            text: getState().courseNotes.note.text,
            edited_by: status.course_note.edited_by,
            updated_at: status.course_note.updated_at
          };
        }
        return note;
    });

    dispatch({ type: UPDATE_NOTES_LIST, updatedNotesList: updatedNotesList });
  } else {
    const messageKey = 'notes.failure';
    const dynamicValue = { operation: 'update' };
    sendNotification(dispatch, 'Error', messageKey, dynamicValue);
  }
};

// Action creator to create a new course note for a given courseId
export const createCourseNote = courseId => async (dispatch, getState) => {
  const courseNoteDetails = { ...getState().courseNotes.note };

  if ((courseNoteDetails.title.trim().length === 0) || (courseNoteDetails.text.trim().length === 0)) {
    return sendNotification(dispatch, 'Error', 'notes.empty_fields');
  }

  const noteDetails = await API.createCourseNote(courseId, courseNoteDetails);

  if (noteDetails?.id) {
    sendNotification(dispatch, 'Success', 'notes.created');
    dispatch({ type: ADD_NEW_NOTE_TO_LIST, newNote: noteDetails });
  } else {
    const messageKey = 'notes.failure';
    const dynamicValue = { operation: 'create' };
    sendNotification(dispatch, 'Error', messageKey, dynamicValue);
  }
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
