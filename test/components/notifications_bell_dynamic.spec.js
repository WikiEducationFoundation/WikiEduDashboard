import {
    triggerNotificationsBellRefresh,
    ACCOUNT_REQUESTS_UPDATED_EVENT,
    CACHE_KEYS
} from '../../app/assets/javascripts/components/nav/notifications_bell';

describe('NotificationsBell Dynamic Updates', () => {
    let mockStorage;
    let dispatchEventSpy;

    beforeEach(() => {
        mockStorage = {
            store: {},
            getItem(key) { return this.store[key] || null; },
            setItem(key, value) { this.store[key] = value.toString(); },
            removeItem(key) { delete this.store[key]; },
            clear() { this.store = {}; }
        };

        // Mock window.dispatchEvent
        dispatchEventSpy = jest.spyOn(window, 'dispatchEvent');

        // Mock sessionStorage
        Object.defineProperty(window, 'sessionStorage', {
            value: mockStorage,
            writable: true
        });
    });

    afterEach(() => {
        jest.restoreAllMocks();
    });

    describe('triggerNotificationsBellRefresh', () => {
        test('clears the cache and dispatches update event', () => {
            // Setup cache with some values
            mockStorage.setItem(CACHE_KEYS.REQUESTED_ACCOUNTS, 'true');
            mockStorage.setItem(CACHE_KEYS.TIMESTAMP, String(Date.now()));

            // Trigger refresh
            triggerNotificationsBellRefresh();

            // Verify cache is cleared
            expect(mockStorage.getItem(CACHE_KEYS.REQUESTED_ACCOUNTS)).toBeNull();
            expect(mockStorage.getItem(CACHE_KEYS.TIMESTAMP)).toBeNull();

            // Verify event dispatched
            expect(dispatchEventSpy).toHaveBeenCalled();
            const event = dispatchEventSpy.mock.calls[0][0];
            expect(event.type).toBe(ACCOUNT_REQUESTS_UPDATED_EVENT);
        });
    });
});
