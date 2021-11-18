import { LATENCY_SUCCESS, LATENCY_LOADING, LATENCY_FAIL } from '../constants/queues_latency';
import API from '../utils/api';


export default function getQueuesLatency() {
  return function (dispatch) {
    dispatch({ type: LATENCY_LOADING });
    return API.getLatency()
      .then(result =>
         (dispatch({
        type: LATENCY_SUCCESS,
        payload: result,
      })))
      .catch(response => (dispatch({
        type: LATENCY_FAIL,
        payload: response,
      })));
  };
}
