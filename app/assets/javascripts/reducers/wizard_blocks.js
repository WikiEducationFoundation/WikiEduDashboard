import {
  RECEIVE_WIZARD_BLOCK_CATALOG,
  REQUEST_WIZARD_BLOCK_CATALOG,
  SANDBOX_MODE_SWITCHED,
  SWITCHING_SANDBOX_MODE
} from '../constants';

const initialState = {
  catalog: [],
  loading: false,
  loaded: false,
  switching: false,
  // The report from the most recent sandbox mode switch: what was added,
  // removed, and what could not be matched or decided.
  lastSwitch: null
};

export default function wizardBlocks(state = initialState, action) {
  switch (action.type) {
    case REQUEST_WIZARD_BLOCK_CATALOG:
      return { ...state, loading: true };
    case RECEIVE_WIZARD_BLOCK_CATALOG:
      return {
        ...state,
        catalog: action.data.blocks,
        loading: false,
        loaded: true
      };
    case SWITCHING_SANDBOX_MODE:
      return { ...state, switching: true, lastSwitch: null };
    case SANDBOX_MODE_SWITCHED:
      return { ...state, switching: false, lastSwitch: action.data };
    default:
      return state;
  }
}
