import API from '../utils/api';
import logErrorMessage from '../utils/log_error_message';
import { ADD_NOTIFICATION } from '../constants/notifications';

import {
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

  return notificationConfig.type;
};

// Action creator to fetch all admin course notes for a given courseId
export const fetchAllAdminCourseNotes = courseId => async (dispatch) => {
  try {
    const notesList = await API.fetchAllAdminCourseNotes(courseId);
    dispatch({ type: RECEIVE_NOTES_LIST, notes_list: notesList });
  } catch (error) {
    logErrorMessage('Error fetching course notes:', error);
  }
};

// Action creator to save the updated/Edited admin course note to Database
export const saveUpdatedAdminCourseNote = adminCourseNoteDetails => async (dispatch, getState) => {
  if ((adminCourseNoteDetails.title.trim().length === 0) || (adminCourseNoteDetails.text.trim().length === 0)) {
    return sendNotification(dispatch, 'Error', 'notes.empty_fields');
  }

  const status = await API.saveUpdatedAdminCourseNote(adminCourseNoteDetails);

  if (status?.success) {
    sendNotification(dispatch, 'Success', 'notes.updated');

    const updatedNotesList = getState().adminCourseNotes.notes_list.map((note) => {
        if (note.id === adminCourseNoteDetails.id) {
          return {
            ...note,
            title: adminCourseNoteDetails.title,
            text: adminCourseNoteDetails.text,
            edited_by: status.admin_course_note.edited_by,
            updated_at: status.admin_course_note.updated_at
          };
        }
        return note;
    });

    dispatch({ type: UPDATE_NOTES_LIST, updatedNotesList });
  } else {
    sendNotification(dispatch, 'Error', 'notes.failure');
  }
};

// Action creator to create a new admin course note for a given courseId
export const createAdminCourseNote = (courseId, adminCourseNoteDetails) => async (dispatch) => {
  if ((adminCourseNoteDetails.title.trim().length === 0) || (adminCourseNoteDetails.text.trim().length === 0)) {
    return sendNotification(dispatch, 'Error', 'notes.empty_fields');
  }

  const noteDetails = await API.createAdminCourseNote(courseId, adminCourseNoteDetails);

  if (noteDetails?.id) {
    sendNotification(dispatch, 'Success', 'notes.created');
    dispatch({ type: ADD_NEW_NOTE_TO_LIST, newNote: noteDetails });
  } else {
    sendNotification(dispatch, 'Error', 'notes.failure');
  }
};

// Action creator to delete a course note from the list based on its ID
export const deleteAdminNoteFromList = noteId => async (dispatch) => {
  const status = await API.deleteAdminCourseNote(noteId);

  if (status?.success) {
    sendNotification(dispatch, 'Success', 'notes.deleted');
    dispatch({ type: DELETE_NOTE_FROM_LIST, deletedNoteId: noteId });
  } else {
    sendNotification(dispatch, 'Error', 'notes.delete_note_error');
  }
};
