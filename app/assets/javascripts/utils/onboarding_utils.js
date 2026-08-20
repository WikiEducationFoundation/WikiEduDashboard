import request, { ensureOk } from '../utils/request';

const OnboardAPI = {
  // /  GETTERS

  async onboard(args) {
    const response = await request('/onboarding/onboard', {
      method: 'PUT',
      body: JSON.stringify(args)
    });
    await ensureOk(response);
    return response.text();
  },

  async supplement(args) {
    const response = await request('/onboarding/supplementary', {
      method: 'PUT',
      body: JSON.stringify(args)
    });
    await ensureOk(response);
    return response.text();
  }
};

export default OnboardAPI;
