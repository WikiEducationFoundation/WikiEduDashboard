import { GET_TAGGED_COURSES_STATS } from '../constants';

const initialState = {
  title: '',
  slug: '',
  courses_count: '',
  user_count: '',
  word_count_human: '',
  references_count_human: '',
  view_sum_human: '',
  article_count_human: '',
  new_article_count_human: '',
  upload_count_human: '',
  course_string_prefix: '',
  trained_percent_human: '',
  upload_usage_count: '',
  uploads_in_use_count: '',
  loading: true
};

export default function taggedCoursesStats(state = initialState, action) {
  switch (action.type) {
    case GET_TAGGED_COURSES_STATS:
      return {
        ...action.tagged_course_stats.stats,
        loading: false
      };
    default:
      return state;
  }
}
