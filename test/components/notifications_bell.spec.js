import '../testHelper';
import {
    SKIP_NOTIFICATION_ROUTES,
    shouldSkipNotificationFetch
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
