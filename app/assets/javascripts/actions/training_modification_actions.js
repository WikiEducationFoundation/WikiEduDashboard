import { API_FAIL } from '../constants/api';
import { addNotification } from '../actions/notification_actions';
import logErrorMessage from '../utils/log_error_message';
import request from '../utils/request';

const createLibraryPromise = async (library, setSubmitting, modalHandler) => {
    const response = await request('/training_library', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(library),
    });
    setSubmitting(false);
    modalHandler(false);
    if (!response.ok) {
      logErrorMessage(response);
      const data = await response.text();
      response.responseText = data;
      throw response;
    }
    return response.json();
  };

export const createLibrary = (library, setSubmitting, modalHandler) => (dispatch) => {
    return createLibraryPromise(library, setSubmitting, modalHandler)
    .then(() => {
        dispatch(addNotification({
            type: 'success',
            message: 'Library Created Successfully.',
            closable: true
        }));
    })
    .catch(error => dispatch({ type: API_FAIL, data: error }));
};
