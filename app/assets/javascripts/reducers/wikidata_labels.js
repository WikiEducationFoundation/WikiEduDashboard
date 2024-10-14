import { forEach } from 'lodash-es';
import { RECEIVE_WIKIDATA_LABELS } from '../constants';

const initialState = {
  labels: {}
};

export default function wikidataLabels(state = initialState, action) {
  switch (action.type) {
    case RECEIVE_WIKIDATA_LABELS: {
      const newLabels = { ...state.labels };
      forEach(action.data.entities, (entity) => {
        if (!entity.labels) { return; }
        const label = entity.labels[action.language] || entity.labels.mul || entity.labels.en;
        if (!label) { return; }
        newLabels[entity.id] = label.value;
      });
      return { labels: newLabels };
    }
    default:
      return state;
  }
}
