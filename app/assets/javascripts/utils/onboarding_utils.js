import logErrorMessage from './log_error_message';
import request from '../utils/request';

const OnboardAPI = {
  // /  GETTERS

  async onboard(args) {
    const response = await request('/onboarding/onboard', {
      method: 'PUT',
      body: JSON.stringify(args)
    });
    if (!response.ok) {
      logErrorMessage(response);
      const data = await response.json();
      throw data;
    }
    return response.json();
  },

  async supplement(args) {
    const response = await request('/onboarding/supplementary', {
      method: 'PUT',
      body: JSON.stringify(args)
    });
    if (!response.ok) {
      logErrorMessage(response);
      const data = await response.json();
      throw data;
    }
    return response.json();
  }
};

export default OnboardAPI;
