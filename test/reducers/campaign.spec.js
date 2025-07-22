import deepFreeze from 'deep-freeze';
import campaign from '../../app/assets/javascripts/reducers/campaign';
import { GET_CAMPAIGN } from '../../app/assets/javascripts/constants';

describe('active_course reducer', () => {
    const sampleCampaign = { id: 1, slug: 'Course_1', loading: true };
    test('should return initial state when no action nor state is provided', () => {
        const newState = campaign(undefined, { type: null });
        expect(newState.courses).toBe(undefined);
    });

    test('should update state with GET_CAMPAIGN action', () => {
         const initialState = {
            id: '',
            slug: '',
            loading: true,
        };
        deepFreeze(initialState);
        const mockedAction = {
            type: GET_CAMPAIGN,
            data: { campaign: { ...sampleCampaign } },
        };
        const newState = campaign(initialState, mockedAction);
        expect(newState.loading).toBe(false);
        expect(newState.slug).toBe('Course_1');
        expect(newState).not.toContainEqual({ ...sampleCampaign });
    });

    test('should return the same state when GET_CAMPAIGN is dispatched multiple times with the same data', () => {
        const initialState = {
            id: '',
            slug: '',
            loading: true,
        };
        deepFreeze(initialState);
        const mockedAction = {
            type: GET_CAMPAIGN,
            data: { campaign: { ...sampleCampaign } },
        };
        const firstState = campaign(initialState, mockedAction);
        const secondState = campaign(firstState, mockedAction);
        expect(firstState).toEqual(secondState);
        expect(secondState.slug).toEqual('Course_1');
        expect(secondState.loading).toBe(false);
    });
});
