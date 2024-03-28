import {
  UPDATE_CURRENT_NOTE,
  RECEIVE_NOTE_DETAILS,
  RESET_TO_ORIGINAL_NOTE,
  PERSISTED_COURSE_NOTE,
  RESET_NOTE_TO_DEFAULT,
  RECEIVE_NOTES_LIST,
  ADD_NEW_NOTE_TO_LIST,
  DELETE_NOTE_FROM_LIST
} from '../constants';

const initialState = {
   notes_list: [],
   note: {
      title: '',
      text: '',
   },
};

export default function courseNotes(state = initialState, action) {
   switch (action.type) {
      case RECEIVE_NOTES_LIST:
         return { ...state, notes_list: action.notes_list };
      case ADD_NEW_NOTE_TO_LIST:
         return { ...state, notes_list: [...state.notes_list, action.newNote] };
       case DELETE_NOTE_FROM_LIST:
         return { ...state, notes_list: state.notes_list.filter(note => note.id !== action.deletedNoteId) };
      case RECEIVE_NOTE_DETAILS:
         return { ...state, note: { ...state.note, ...action.note } };
      case UPDATE_CURRENT_NOTE:
         return { ...state, note: { ...state.note, ...action.note } };
      case PERSISTED_COURSE_NOTE:
         return { ...state, note: { ...state.note, ...action.note } };
      case RESET_TO_ORIGINAL_NOTE:
         return { ...state, note: { ...state.note, ...action.note } };
      case RESET_NOTE_TO_DEFAULT:
         return { ...initialState, notes_list: state.notes_list };
      default:
         return state;
   }
}

