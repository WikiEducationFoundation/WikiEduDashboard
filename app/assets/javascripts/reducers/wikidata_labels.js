import _ from 'lodash';
import { RECEIVE_WIKIDATA_LABELS } from '../constants';

const initialState = {
  labels: {}
};

export default function wikidataLabels(state = initialState, action) {
  switch (action.type) {
    case RECEIVE_WIKIDATA_LABELS: {
      const newLabels = { ...state.labels };
      _.forEach(action.data.entities, (entity) => {
        const label = entity.labels[action.language] || entity.labels.en;
        if (!label) { return; }
        newLabels[entity.id] = label.value;
      });
      return { labels: newLabels };
    }
    default:
      return state;
  }
}
