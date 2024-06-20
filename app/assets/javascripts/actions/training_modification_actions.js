import { API_FAIL } from '../constants/api';
import { addNotification } from '../actions/notification_actions';
import logErrorMessage from '../utils/log_error_message';
import request from '../utils/request';
import { setInvalid } from './validation_actions';

const libraryValidationRules = [
  { keyword: 'name', field: 'name' },
  { keyword: 'slug', field: 'slug' },
  { keyword: 'introduction', field: 'introduction' }
];

const categoryValidationRules = [
  { keyword: 'title', field: 'title' },
  { keyword: 'description', field: 'description' }
];

const performValidation = (error, dispatch, validationRules) => {
  const errorMessages = error.responseText.errorMessages;
  let apiFailDispatched = false;

  for (let i = 0; i < errorMessages.length; i += 1) {
    const message = errorMessages[i];
    const lowercaseMessage = message.toLowerCase();
    const matchedRule = validationRules.find(rule => lowercaseMessage.includes(rule.keyword));

    if (matchedRule) {
      dispatch(setInvalid(matchedRule.field, message));
    } else {
      if (!apiFailDispatched) {
        dispatch({ type: API_FAIL, data: error });
        apiFailDispatched = true;
      }
      return;
    }
  }
};


const createLibraryPromise = async (library, setSubmitting) => {
  const response = await request('/training/create_library', {
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
    window.location.reload();
  })
  .catch((error) => {
    performValidation(error, dispatch, libraryValidationRules);
  });
};

const createCategoryPromise = async (library_id, category, setSubmitting) => {
  const response = await request(`/training/${library_id}/create_category`, {
    method: 'POST',
    body: JSON.stringify({ category }),
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

export const createCategory = (library_id, category, setSubmitting, toggleModal) => (dispatch) => {
  return createCategoryPromise(library_id, category, setSubmitting)
  .then(() => {
      toggleModal();
      dispatch(addNotification({
          type: 'success',
          message: 'Category Created Successfully.',
          closable: true
      }));
      window.location.reload();
  })
  .catch((error) => {
    performValidation(error, dispatch, categoryValidationRules);
  });
};
