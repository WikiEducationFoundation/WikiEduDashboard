import { LATENCY_SUCCESS, LATENCY_LOADING, LATENCY_FAIL } from '../constants/queues_latency';

const initialState = {
  loading: false,
  data: {},
  errorMSG: '',
};

export default function queuesLatency(state = initialState, action) {
  switch (action.type) {
    case LATENCY_LOADING: {
      return {
        ...state, loading: true, data: {}, errorMSG: '',
      };
    }
    case LATENCY_SUCCESS: {
      return {
        ...state, loading: false, data: action.payload, errorMSG: '',
      };
    }
    case LATENCY_FAIL: {
      return {
        ...state, loading: false, data: {}, errorMSG: action.payload,
      };
    }
    default:
      return state;
  }
}
