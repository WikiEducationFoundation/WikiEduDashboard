const logErrorMessage = (obj, prefix) => {
  // readyState 0 usually indicates that the user navigated away before ajax
  // requests resolved.
  if (obj.readyState === 0) { return; }
  let message = prefix || 'Error: ';
  message += (obj.responseJSON && obj.responseJSON.message) || obj.statusText;
  return console.log(message); // eslint-disable-line no-console
};

export default logErrorMessage;
