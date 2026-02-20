import '../testHelper';
import {
    SKIP_NOTIFICATION_ROUTES,
    shouldSkipNotificationFetch,
    CACHE_KEYS,
    CACHE_TTL_MS,
    isCacheValid,
    getCached,
    setCache
} from '../../app/assets/javascripts/components/nav/notifications_bell';

describe('NotificationsBell', () => {
    describe('SKIP_NOTIFICATION_ROUTES', () => {
        test('contains expected routes', () => {
            expect(SKIP_NOTIFICATION_ROUTES).toContain('/survey');
            expect(SKIP_NOTIFICATION_ROUTES).toContain('/faq');
            expect(SKIP_NOTIFICATION_ROUTES).toContain('/training');
            expect(SKIP_NOTIFICATION_ROUTES).toContain('/onboarding');
        });
    });

    describe('shouldSkipNotificationFetch', () => {
        describe('returns false (should fetch) for relevant routes', () => {
            test('dashboard route', () => {
                expect(shouldSkipNotificationFetch('/dashboard')).toBe(false);
            });

            test('courses route', () => {
                expect(shouldSkipNotificationFetch('/courses/some-course')).toBe(false);
            });

            test('root route', () => {
                expect(shouldSkipNotificationFetch('/')).toBe(false);
            });

            test('admin route', () => {
                expect(shouldSkipNotificationFetch('/admin')).toBe(false);
            });

            test('requested_accounts route', () => {
                expect(shouldSkipNotificationFetch('/requested_accounts')).toBe(false);
            });
        });

        describe('returns true (should skip) for survey routes', () => {
            test('/survey', () => {
                expect(shouldSkipNotificationFetch('/survey')).toBe(true);
            });

            test('/surveys', () => {
                expect(shouldSkipNotificationFetch('/surveys')).toBe(true);
            });

            test('/surveys/123', () => {
                expect(shouldSkipNotificationFetch('/surveys/123')).toBe(true);
            });

            test('/survey/results/123', () => {
                expect(shouldSkipNotificationFetch('/survey/results/123')).toBe(true);
            });
        });

        describe('returns true (should skip) for faq routes', () => {
            test('/faq', () => {
                expect(shouldSkipNotificationFetch('/faq')).toBe(true);
            });

            test('/faq/123', () => {
                expect(shouldSkipNotificationFetch('/faq/123')).toBe(true);
            });

            test('/faq_topics', () => {
                expect(shouldSkipNotificationFetch('/faq_topics')).toBe(true);
            });
        });

        describe('returns true (should skip) for training routes', () => {
            test('/training', () => {
                expect(shouldSkipNotificationFetch('/training')).toBe(true);
            });

            test('/training/library_id', () => {
                expect(shouldSkipNotificationFetch('/training/library_id')).toBe(true);
            });

            test('/training/library_id/module_id', () => {
                expect(shouldSkipNotificationFetch('/training/library_id/module_id')).toBe(true);
            });
        });

        describe('returns true (should skip) for onboarding routes', () => {
            test('/onboarding', () => {
                expect(shouldSkipNotificationFetch('/onboarding')).toBe(true);
            });

            test('/onboarding/step1', () => {
                expect(shouldSkipNotificationFetch('/onboarding/step1')).toBe(true);
            });
        });
    });
});

describe('NotificationsBell Cache', () => {
    // Mock sessionStorage
    let mockStorage;

    beforeEach(() => {
        mockStorage = {
            store: {},
            getItem(key) {
                return this.store[key] || null;
            },
            setItem(key, value) {
                this.store[key] = value;
            },
            removeItem(key) {
                delete this.store[key];
            },
            clear() {
                this.store = {};
            }
        };
    });

    describe('CACHE_KEYS', () => {
        test('contains expected keys', () => {
            expect(CACHE_KEYS.REQUESTED_ACCOUNTS).toBe('notifications_requested_accounts');
            expect(CACHE_KEYS.OPEN_TICKETS).toBe('notifications_open_tickets');
            expect(CACHE_KEYS.TIMESTAMP).toBe('notifications_cache_timestamp');
        });
    });

    describe('CACHE_TTL_MS', () => {
        test('is set to 30 seconds', () => {
            expect(CACHE_TTL_MS).toBe(30000);
        });
    });

    describe('isCacheValid', () => {
        test('returns false when no timestamp exists', () => {
            expect(isCacheValid(mockStorage)).toBe(false);
        });

        test('returns true when timestamp is within TTL', () => {
            mockStorage.setItem(CACHE_KEYS.TIMESTAMP, String(Date.now()));
            expect(isCacheValid(mockStorage)).toBe(true);
        });

        test('returns true when timestamp is 10 seconds ago', () => {
            mockStorage.setItem(CACHE_KEYS.TIMESTAMP, String(Date.now() - 10000));
            expect(isCacheValid(mockStorage)).toBe(true);
        });

        test('returns true when timestamp is 29 seconds ago', () => {
            mockStorage.setItem(CACHE_KEYS.TIMESTAMP, String(Date.now() - 29000));
            expect(isCacheValid(mockStorage)).toBe(true);
        });

        test('returns false when timestamp is 31 seconds ago (expired)', () => {
            mockStorage.setItem(CACHE_KEYS.TIMESTAMP, String(Date.now() - 31000));
            expect(isCacheValid(mockStorage)).toBe(false);
        });

        test('returns false when timestamp is 60 seconds ago', () => {
            mockStorage.setItem(CACHE_KEYS.TIMESTAMP, String(Date.now() - 60000));
            expect(isCacheValid(mockStorage)).toBe(false);
        });
    });

    describe('getCached', () => {
        test('returns null when cache is not valid', () => {
            expect(getCached(CACHE_KEYS.REQUESTED_ACCOUNTS, mockStorage)).toBeNull();
        });

        test('returns null when key does not exist but cache is valid', () => {
            mockStorage.setItem(CACHE_KEYS.TIMESTAMP, String(Date.now()));
            expect(getCached(CACHE_KEYS.REQUESTED_ACCOUNTS, mockStorage)).toBeNull();
        });

        test('returns true when cached value is "true"', () => {
            mockStorage.setItem(CACHE_KEYS.TIMESTAMP, String(Date.now()));
            mockStorage.setItem(CACHE_KEYS.REQUESTED_ACCOUNTS, 'true');
            expect(getCached(CACHE_KEYS.REQUESTED_ACCOUNTS, mockStorage)).toBe(true);
        });

        test('returns false when cached value is "false"', () => {
            mockStorage.setItem(CACHE_KEYS.TIMESTAMP, String(Date.now()));
            mockStorage.setItem(CACHE_KEYS.REQUESTED_ACCOUNTS, 'false');
            expect(getCached(CACHE_KEYS.REQUESTED_ACCOUNTS, mockStorage)).toBe(false);
        });

        test('returns null when cache is expired even if value exists', () => {
            mockStorage.setItem(CACHE_KEYS.TIMESTAMP, String(Date.now() - 60000));
            mockStorage.setItem(CACHE_KEYS.REQUESTED_ACCOUNTS, 'true');
            expect(getCached(CACHE_KEYS.REQUESTED_ACCOUNTS, mockStorage)).toBeNull();
        });
    });

    describe('setCache', () => {
        test('stores value as string', () => {
            setCache(CACHE_KEYS.REQUESTED_ACCOUNTS, true, mockStorage);
            expect(mockStorage.getItem(CACHE_KEYS.REQUESTED_ACCOUNTS)).toBe('true');
        });

        test('stores false value as "false" string', () => {
            setCache(CACHE_KEYS.REQUESTED_ACCOUNTS, false, mockStorage);
            expect(mockStorage.getItem(CACHE_KEYS.REQUESTED_ACCOUNTS)).toBe('false');
        });

        test('updates timestamp when setting cache', () => {
            const before = Date.now();
            setCache(CACHE_KEYS.REQUESTED_ACCOUNTS, true, mockStorage);
            const timestamp = parseInt(mockStorage.getItem(CACHE_KEYS.TIMESTAMP));
            const after = Date.now();
            expect(timestamp).toBeGreaterThanOrEqual(before);
            expect(timestamp).toBeLessThanOrEqual(after);
        });
    });

    describe('Performance comparison (before vs after)', () => {
        test('demonstrates API call savings when cache is valid', () => {
            // Simulate fresh cache
            mockStorage.setItem(CACHE_KEYS.TIMESTAMP, String(Date.now()));
            mockStorage.setItem(CACHE_KEYS.REQUESTED_ACCOUNTS, 'true');

            // BEFORE: Without caching - always makes API call
            const beforeApiCalls = 1;

            // AFTER: With caching - skips API call if cache is valid
            const cacheValid = isCacheValid(mockStorage);
            const afterApiCalls = cacheValid ? 0 : 1;

            expect(cacheValid).toBe(true);
            expect(afterApiCalls).toBe(0);
            expect(beforeApiCalls - afterApiCalls).toBe(1); // Saved 1 API call
        });

        test('shows API call made when cache is expired', () => {
            // Simulate expired cache (31 seconds ago)
            mockStorage.setItem(CACHE_KEYS.TIMESTAMP, String(Date.now() - 31000));
            mockStorage.setItem(CACHE_KEYS.REQUESTED_ACCOUNTS, 'true');

            const cacheValid = isCacheValid(mockStorage);
            const apiCalls = cacheValid ? 0 : 1;

            expect(cacheValid).toBe(false);
            expect(apiCalls).toBe(1); // Fresh data fetched as expected
        });
    });
});
