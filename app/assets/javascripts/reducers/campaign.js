import {
  GET_CAMPAIGN
} from '../constants';

const initialState = {
  id: '',
  title: '',
  slug: '',
  description: '',
  template_description: '',
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
  uploads_in_use_count: '',
  upload_usage_count_human: '',
  upload_usage_count: '',
  trained_percent_human: '',
  course_string_prefix: '',
  show_the_create_course_button: false,
  editable: false,
  register_accounts: '',
  start: false,
  end: false,
  loading: true,
  course_stats: {}
};

export default function campaign(state = initialState, action) {
  switch (action.type) {
    case GET_CAMPAIGN:
      return {
        ...action.data.campaign,
        loading: false
      };
    default:
      return state;
  }
}
