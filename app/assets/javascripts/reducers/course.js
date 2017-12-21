import { RECEIVE_INITIAL_CAMPAIGN, RECEIVE_COURSE_CLONE, UPDATE_COURSE, CREATED_COURSE } from "../constants";

const initialState = {
  title: '',
  description: '',
  school: '',
  term: '',
  level: '',
  subject: '',
  expected_students: '0',
  start: null,
  end: null,
  day_exceptions: '',
  weekdays: '0000000',
  editingSyllabus: false
};

export default function course(state = initialState, action) {
  switch (action.type) {
    case UPDATE_COURSE:
      return { ...state, ...action.course };
    case CREATED_COURSE:
      return { ...action.data.course };
    case RECEIVE_INITIAL_CAMPAIGN: {
      const campaign = action.data.campaign;
      const newState = {
        ...state,
        initial_campaign_id: campaign.id,
        initial_campaign_title: campaign.title,
        description: campaign.template_description
      };
      return newState;
    }
    case RECEIVE_COURSE_CLONE:
      return { ...action.data.course };
    default:
      return state;
  }
}
