import { setInvalid } from '../actions/validation_actions.js';

export const firstMessage = (validation) => {
  if (validation.errorQueue.length > 0) {
    return validation.validations[validation.errorQueue[0]].message;
  }
  return null;
}

export const isValid = (validations) => {
  let valid = true;
  const iterable = Object.keys(validations);
  for (let i = 0; i < iterable.length; i++) {
    const key = iterable[i];
    if (!validations[key].changed && !validations[key].valid) {
      setInvalid(key,validations[key].message);
    }
    valid = valid && validations[key].valid;
  }
  return valid;
}

export const getValidation = (key, validations) => {
  if ((validations[key]) && validations[key].changed) {
    return validations[key].valid;
  }
  return true;
}
