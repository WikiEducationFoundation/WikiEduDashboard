import logErrorMessage from './log_error_message';

const OnboardAPI = {
  /// GETTERS

  onboard(data) {
    return new Promise((res, rej) =>
      $.ajax({
        type: 'PUT',
        url: '/onboarding/onboard',
        contentType: 'application/json',
        data: JSON.stringify(data),
        success(data) {
          return res(data);
        }
      })
      .fail((obj) => {
        logErrorMessage(obj);
        return rej(obj);
      })
    );
  },

  supplement(data) {
    return new Promise((res, rej) =>
      $.ajax({
        type: 'PUT',
        url: '/onboarding/supplementary',
        contentType: 'application/json',
        data: JSON.stringify(data),
        success(data) {
          return res(data);
        }
      })
      .fail((obj) => {
        logErrorMessage(obj);
        return rej(obj);
      })
    );
  }
}
