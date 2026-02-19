import '../testHelper';
import API from '../../app/assets/javascripts/utils/api';

// Mock the request utility to simulate API responses
jest.mock('../../app/assets/javascripts/utils/request', () => {
    return jest.fn(() =>
        Promise.resolve({
            ok: true,
            json: () => Promise.resolve({ newsDetails: [{ id: 1, content: 'News 1' }] }),
        })
    );
});

jest.mock('@rails/ujs', () => ({ csrfToken: () => 'test-token' }));
jest.mock('../../app/assets/javascripts/utils/log_error_message');

const request = require('../../app/assets/javascripts/utils/request');

describe('API.fetchNews throttle', () => {
    afterEach(() => {
        jest.clearAllMocks();
    });

    test('does not make a duplicate API call within the throttle window', async () => {
        // First call — should hit the server
        await API.fetchNews();
        expect(request).toHaveBeenCalledTimes(1);

        // Second call within 5s — should return cached result
        await API.fetchNews();
        expect(request).toHaveBeenCalledTimes(1); // still 1, no new call
    });

    test('returns the same data from cache on the second call', async () => {
        const result1 = await API.fetchNews();
        const result2 = await API.fetchNews();
        expect(result2).toEqual(result1);
    });
});
