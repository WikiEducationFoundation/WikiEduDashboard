import { RECEIVE_INITIAL_CAMPAIGN, UPDATE_COURSE } from "../constants";

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
      return { ...state, ...data.course };
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
    default:
      return state;
  }
}
