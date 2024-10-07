import deepFreeze from 'deep-freeze';
import campaigns from '../../app/assets/javascripts/reducers/campaigns';
import {
    RECEIVE_COURSE_CAMPAIGNS,
    RECEIVE_ALL_CAMPAIGNS,
    ADD_CAMPAIGN,
    SORT_CAMPAIGNS_WITH_STATS,
    SORT_ALL_CAMPAIGNS } from '../../app/assets/javascripts/constants';

const campaignsArray = [
      { id: 2, slug: 'second_campaign', description: 'second description' },
        { id: 1, slug: 'first_campaign', description: 'first description' }
      ];
 const sortedcampaignsArray = [
      { id: 1, slug: 'first_campaign', description: 'first description' },
      { id: 2, slug: 'second_campaign', description: 'second description' },
      ];

describe('campaigns reducer', () => {
    test('should return initial state when no action nor state is provided', () => {
        const newState = campaigns(undefined, { type: null });
        expect(newState.campaigns).toEqual([]);
        expect(newState.all_campaigns).toEqual([]);
        expect(newState.isLoaded).toBe(false);
    });

    test('should add and return campaigns data with ADD_CAMPAIGN and set isLoaded to true', () => {
        const initialState = { campaigns: [], all_campaigns: [], isLoaded: false };
        deepFreeze(initialState);

        const mockedAction = {
          type: ADD_CAMPAIGN,
          data: { course: { campaigns: campaignsArray[0] } }
        };

        const newState = campaigns(initialState, mockedAction);
        expect(newState.campaigns).toContainEqual(campaignsArray[0]);
        expect(newState.isLoaded).toBe(true);
        expect(Array.isArray(newState.campaigns)).toBe(true);
      });

      test('should receives and return  course campaigns and update initial course campaigns with RECEIVE_COURSE_CAMPAIGNS', () => {
        const initialState = { campaigns: [{ id: 3, slug: 'third_campaign', description: 'first description' }],
                            all_campaigns: [],
                            isLoaded: false };
        deepFreeze(initialState);

        const mockedAction = {
          type: RECEIVE_COURSE_CAMPAIGNS,
          data: { course: { campaigns: campaignsArray } }
        };

        const newState = campaigns(initialState, mockedAction);
        expect(newState.campaigns).toEqual(campaignsArray);
        expect(newState.isLoaded).toBe(true);
      });

      test('should receives all campaigns with RECEIVE_ALL_CAMPAIGNS and set all_campaigns_loaded to true', () => {
        const initialState = { campaigns: [], all_campaigns: [], all_campaigns_loaded: false };
        deepFreeze(initialState);

        const mockedAction = {
          type: RECEIVE_ALL_CAMPAIGNS,
          data: { campaigns: campaignsArray }
        };

        const newState = campaigns(initialState, mockedAction);
        expect(newState.all_campaigns).toEqual(campaignsArray);
        expect(newState.all_campaigns_loaded).toBe(true);
      });

      test('sort active courses via SORT_ACTIVE_CAMPAIGN', () => {
        const initialState = { campaigns: [], all_campaigns: campaignsArray, isLoaded: false, sort: { sortKey: null } };
        deepFreeze(initialState);

        const mockedAction = {
            type: SORT_ALL_CAMPAIGNS,
            key: 'id'
        };

        const newState = campaigns(initialState, mockedAction);
        expect(newState.sort.key).toBe('id');
        expect(newState.all_campaigns).toEqual(sortedcampaignsArray);
    });

    test('should not modify courses when SORT_ACTIVE_COURSES or SORT_CAMPAIGNS_WITH_STATS is dispatched with an invalid key', () => {
        const initialState = { all_campaigns: campaignsArray, sort: { sortKey: null, key: null } };
        deepFreeze(initialState);

        const mockedAction = {
            type: SORT_CAMPAIGNS_WITH_STATS,
            key: 'nonExistentKey',
        };
        const newState = campaigns(initialState, mockedAction);
        expect(newState.all_campaigns).toEqual(initialState.all_campaigns);
        expect(newState.sort.key).toBe('nonExistentKey');
    });
});
