import {
  GET_CAMPAIGN
} from '../constants';

const initialState = {
  id: '',
  title: '',
  slug: '',
  description: '',
  template_description: null,
  default_course_type: '',
  default_passcode: '',
  uploads_in_use_count: undefined,
};

export default function campaign(state = initialState, action) {
  // console.log(`action from campaign reducer:${action}`);
  switch (action.type) {
    case GET_CAMPAIGN:
      // console.log(`action.data from campaign reducer: ${action.object}`);
      // console.log(`action.data.campaign from campaign reducer: ${action.data.campaign}`);
      return { ...action.data.campaign };
    default:
      // console.log(`default state: ${state}`);
      return state;
  }
}
