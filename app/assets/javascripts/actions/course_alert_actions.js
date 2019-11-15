import * as types from '../constants';
import request from '../utils/request';

export const fetchOnboardingAlert = ({ id = null }) => (dispatch) => {
  const idQuery = id ? `course_id=${id}` : '';
  return request(`/alerts_list.json?type=OnboardingAlert&${idQuery}`)
    .then((res) => {
      if (res.ok && res.status === 200) {
        return res.json();
      }
      return Promise.reject(res);
    })
    .then(data => dispatch({ type: types.RECEIVE_ONBOARDING_ALERT, data }))
    .catch(data => dispatch({ type: types.API_FAIL, data, silent: true }));
};
