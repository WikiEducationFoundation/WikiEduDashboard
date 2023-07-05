import deepFreeze from 'deep-freeze';
import alerts from '../../app/assets/javascripts/reducers/alerts';
import {
  RECEIVE_ALERTS,
  SORT_ALERTS,
  FILTER_ALERTS
} from '../../app/assets/javascripts/constants';
import '../testHelper';

describe('course reducer', () => {
  test(
    'assigns alerts to passed alerts and sorts them via RECEIVE_ALERTS',
    () => {
      const initialState = { alerts: [] };
      deepFreeze(initialState);
      const action = { type: RECEIVE_ALERTS,
        data: { alerts: [{ created_at: 1 }, { created_at: 2 }] }
      };
      const expectedSortedAlerts = [{ created_at: 2 }, { created_at: 1 }];

      const newState = alerts(initialState, action);
      expect(newState.alerts).toEqual(expectedSortedAlerts);
    }
  );

  test('sorts existing alerts via SORT_ALERTS', () => {
    const initialState = { alerts: [{ custom_key: 2 }, { custom_key: 1 }] };
    deepFreeze(initialState);
    const action = { type: SORT_ALERTS, key: 'custom_key' };
    const expectedSortedAlerts = [{ custom_key: 1 }, { custom_key: 2 }];

    const newState = alerts(initialState, action);
    expect(newState.alerts).toEqual(expectedSortedAlerts);
    expect(newState.sortKey).toBe('custom_key');
  });

  test('assigns selectedFilters via FILTER_ALERTS', () => {
    const initialState = { alerts: [] };
    deepFreeze(initialState);
    const action = { type: FILTER_ALERTS, selectedFilters: 'foo' };

    const newState = alerts(initialState, action);
    expect(newState.selectedFilters).toBe('foo');
  });
});
