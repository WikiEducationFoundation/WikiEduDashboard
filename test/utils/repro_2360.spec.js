import '../testHelper';
import CourseDateUtils from '../../app/assets/javascripts/utils/course_date_utils';
import { startOfWeek } from 'date-fns';
import { toDate } from '../../app/assets/javascripts/utils/date_utils';

describe('Issue #2360: Sunday Timeline Start', () => {
    // This is the EXACT scenario from the user's test course
    const course = {
        start: '2026-02-12', // Thursday
        timeline_start: '2026-02-15', // SUNDAY
        end: '2026-03-24',
        timeline_end: '2026-03-24',
        weekdays: '0010100', // Tuesday, Thursday
        day_exceptions: ''
    };

    test('PROOF 1: Does weekMeetings produce a non-empty first week?', () => {
        const meetings = CourseDateUtils.weekMeetings(course, '');
        expect(meetings[0].length).toBeGreaterThan(0);
    });

    test('PROOF 2: Does weeksBeforeTimeline return zero for the expected start?', () => {
        const wbt = CourseDateUtils.weeksBeforeTimeline(course);
        expect(wbt).toBe(0);
    });

    test('PROOF 4: What if course.start IS the same Sunday?', () => {
        const sameDayCourse = {
            ...course,
            start: '2026-02-15', // Same Sunday as timeline_start
        };
        const meetings = CourseDateUtils.weekMeetings(sameDayCourse, '');
        const wbt = CourseDateUtils.weeksBeforeTimeline(sameDayCourse);

        expect(wbt).toBe(0);
        expect(meetings[0].length).toBeGreaterThan(0);
    });

    test('PROOF 5: What if course starts Saturday, timeline starts Sunday?', () => {
        const satSunCourse = {
            ...course,
            start: '2026-02-14', // Saturday — just 1 day before Sunday timeline
        };
        const wbt = CourseDateUtils.weeksBeforeTimeline(satSunCourse);
        const meetings = CourseDateUtils.weekMeetings(satSunCourse, '');

        expect(wbt).toBe(0);
        expect(meetings[0].length).toBeGreaterThan(0);
    });
});
