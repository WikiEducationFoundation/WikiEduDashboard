import {
  UPDATE_CURRENT_NOTE,
  RECEIVE_NOTE_DETAILS,
  RESET_NOTE_TO_DEFAULT,
  RECEIVE_NOTES_LIST,
  ADD_NEW_NOTE_TO_LIST,
  DELETE_NOTE_FROM_LIST,
  UPDATE_NOTES_LIST
} from '../constants';

const initialState = {
   notes_list: [],
   note: {
      title: '',
      text: '',
   },
};

export default function adminCourseNotes(state = initialState, action) {
   switch (action.type) {
      case RECEIVE_NOTES_LIST:
         return { ...state, notes_list: action.notes_list };
      case ADD_NEW_NOTE_TO_LIST:
         return { ...state, notes_list: [...state.notes_list, action.newNote] };
      case DELETE_NOTE_FROM_LIST:
         return { ...state, notes_list: state.notes_list.filter(note => note.id !== action.deletedNoteId) };
      case UPDATE_NOTES_LIST:
         return { ...state, notes_list: action.updatedNotesList };
      case RECEIVE_NOTE_DETAILS:
         return { ...state, note: { ...state.note, ...action.note } };
      case UPDATE_CURRENT_NOTE:
         return { ...state, note: { ...state.note, ...action.note } };
      case RESET_NOTE_TO_DEFAULT:
         return { ...initialState, notes_list: state.notes_list };
      default:
         return state;
   }
}

