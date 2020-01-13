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
  courses_count: '',
  user_count: '',
  new_article_count_human: '',
  word_count_human: '',
  references_count_human: '',
  view_sum_human: '',
  article_count_human: '',
  upload_count_human: '',
  uploads_in_use_count_human: '',
  uploads_in_use_count: undefined,
  upload_usage_count_human: '',
  upload_usage_count: '',
  trained_percent_human: '',
  course_string_prefix: ''
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
