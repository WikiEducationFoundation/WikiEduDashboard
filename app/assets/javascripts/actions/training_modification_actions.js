import { API_FAIL } from '../constants/api';
import { addNotification } from '../actions/notification_actions';
import logErrorMessage from '../utils/log_error_message';
import request from '../utils/request';
import { setInvalid } from './validation_actions';

const performValidation = (error, dispatch) => {
  const messages = error.responseText.message;
  messages.forEach((message) => {
    const lowercaseMessage = message.toLowerCase();
    if (lowercaseMessage.includes('name')) {
      dispatch(setInvalid('name', message));
    } else if (lowercaseMessage.includes('slug')) {
      dispatch(setInvalid('slug', message));
    } else if (lowercaseMessage.includes('introduction')) {
      dispatch(setInvalid('introduction', message));
    } else {
      dispatch({ type: API_FAIL, data: error });
    }
  });
};

const createLibraryPromise = async (library, setSubmitting) => {
    const response = await request('/training_library', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(library),
    });
    setSubmitting(false);
    if (!response.ok) {
      logErrorMessage(response);
      const data = await response.json();
      response.responseText = data;
      throw response;
    }
    return response.json();
  };

export const createLibrary = (library, setSubmitting, toggleModal) => (dispatch) => {
    return createLibraryPromise(library, setSubmitting)
    .then(() => {
        toggleModal();
        dispatch(addNotification({
            type: 'success',
            message: 'Library Created Successfully.',
            closable: true
        }));
    })
    .catch((error) => {
      performValidation(error, dispatch);
    });
};
