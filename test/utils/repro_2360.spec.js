import '../testHelper';
import CourseDateUtils from '../../app/assets/javascripts/utils/course_date_utils';
import { startOfWeek, differenceInWeeks } from 'date-fns';
import { toDate } from '../../app/assets/javascripts/utils/date_utils';

describe('Issue #2360: Sunday Timeline Start', () => {
    // This is the EXACT scenario from the user's test course
    const course = {
        start: '2026-02-12',           // Thursday
        timeline_start: '2026-02-15',  // SUNDAY
        end: '2026-03-24',
        timeline_end: '2026-03-24',
        weekdays: '0010100',           // Tuesday, Thursday
        day_exceptions: ''
    };

    test('PROOF 1: Does weekMeetings produce an empty first week?', () => {
        const meetings = CourseDateUtils.weekMeetings(course, '');
        console.log('\n=== weekMeetings output ===');
        meetings.forEach((week, i) => {
            console.log(`  Week ${i}: [${week.join(', ')}] (${week.length} meetings)`);
        });

        console.log(`\n  meetings[0] is empty? ${meetings[0].length === 0}`);
        console.log(`  BUG EXISTS (empty Week 1)? ${meetings[0].length === 0 ? 'YES ❌' : 'NO ✅'}`);
    });

    test('PROOF 2: Does weeksBeforeTimeline add a phantom offset?', () => {
        const wbt = CourseDateUtils.weeksBeforeTimeline(course);
        console.log('\n=== weeksBeforeTimeline ===');
        console.log(`  course.start: ${course.start} (${toDate(course.start).toDateString()})`);
        console.log(`  course.timeline_start: ${course.timeline_start} (${toDate(course.timeline_start).toDateString()})`);
        console.log(`  startOfWeek(course.start): ${startOfWeek(toDate(course.start)).toDateString()}`);
        console.log(`  startOfWeek(timeline_start): ${startOfWeek(toDate(course.timeline_start)).toDateString()}`);
        console.log(`  weeksBeforeTimeline = ${wbt}`);
        console.log(`  BUG EXISTS (phantom offset)? ${wbt > 0 ? 'YES ❌ — Week 1 becomes Week ' + (wbt + 1) : 'NO ✅'}`);
    });

    test('PROOF 3: date-fns startOfWeek default (is it Sunday or locale-based?)', () => {
        const sunday = toDate('2026-02-15'); // Sunday
        const saturday = toDate('2026-02-14'); // Saturday (day before)

        const sowSunday = startOfWeek(sunday);
        const sowSaturday = startOfWeek(saturday);

        console.log('\n=== date-fns startOfWeek defaults ===');
        console.log(`  startOfWeek(Sunday Feb 15): ${sowSunday.toDateString()}`);
        console.log(`  startOfWeek(Saturday Feb 14): ${sowSaturday.toDateString()}`);
        console.log(`  Are they the same week? ${sowSunday.getTime() === sowSaturday.getTime() ? 'YES' : 'NO — different weeks!'}`);
        console.log(`  Default weekStartsOn: ${sowSunday.getDay() === 0 ? '0 (Sunday) — US default' : sowSunday.getDay() + ' (NOT Sunday!)'}`);
    });

    test('PROOF 4: What if course.start IS the same Sunday?', () => {
        const sameDayCourse = {
            ...course,
            start: '2026-02-15', // Same Sunday as timeline_start
        };
        const meetings = CourseDateUtils.weekMeetings(sameDayCourse, '');
        const wbt = CourseDateUtils.weeksBeforeTimeline(sameDayCourse);

        console.log('\n=== Same-day start (both Sunday) ===');
        console.log(`  weeksBeforeTimeline = ${wbt}`);
        console.log(`  meetings[0]: [${meetings[0].join(', ')}]`);
        console.log(`  BUG? ${meetings[0].length === 0 || wbt > 0 ? 'YES ❌' : 'NO ✅'}`);
    });

    test('PROOF 5: What if course starts Saturday, timeline starts Sunday?', () => {
        const satSunCourse = {
            ...course,
            start: '2026-02-14', // Saturday — just 1 day before Sunday timeline
        };
        const wbt = CourseDateUtils.weeksBeforeTimeline(satSunCourse);
        const meetings = CourseDateUtils.weekMeetings(satSunCourse, '');

        console.log('\n=== Saturday start → Sunday timeline (1 day gap) ===');
        console.log(`  startOfWeek(Sat Feb 14): ${startOfWeek(toDate('2026-02-14')).toDateString()}`);
        console.log(`  startOfWeek(Sun Feb 15): ${startOfWeek(toDate('2026-02-15')).toDateString()}`);
        console.log(`  weeksBeforeTimeline = ${wbt}`);
        console.log(`  meetings[0]: [${meetings[0].join(', ')}]`);
        console.log(`  BUG (phantom week)? ${wbt > 0 ? 'YES ❌ — 1 day gap creates a full phantom week!' : 'NO ✅'}`);
    });
});
