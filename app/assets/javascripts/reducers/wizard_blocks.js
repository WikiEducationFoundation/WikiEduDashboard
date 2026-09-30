import {
  RECEIVE_WIZARD_BLOCK_CATALOG,
  REQUEST_WIZARD_BLOCK_CATALOG,
  WIZARD_BLOCK_CATALOG_FAILED,
  SANDBOX_MODE_SWITCHED,
  SANDBOX_MODE_SWITCH_FAILED,
  SWITCHING_SANDBOX_MODE
} from '../constants';

const initialState = {
  catalog: [],
  loading: false,
  switching: false,
  // The report from the most recent sandbox mode switch: what was added,
  // removed, and what could not be matched or decided, plus the slug of the
  // course it describes, since the store outlives navigation between courses.
  lastSwitch: null
};

export default function wizardBlocks(state = initialState, action) {
  switch (action.type) {
    case REQUEST_WIZARD_BLOCK_CATALOG:
      return { ...state, loading: true };
    case RECEIVE_WIZARD_BLOCK_CATALOG:
      return { ...state, catalog: action.data.blocks, loading: false };
    case WIZARD_BLOCK_CATALOG_FAILED:
      return { ...state, loading: false };
    case SWITCHING_SANDBOX_MODE:
      return { ...state, switching: true, lastSwitch: null };
    case SANDBOX_MODE_SWITCHED:
      return {
        ...state,
        switching: false,
        lastSwitch: { ...action.data, courseSlug: action.courseSlug }
      };
    case SANDBOX_MODE_SWITCH_FAILED:
      return { ...state, switching: false };
    default:
      return state;
  }
}
