import '../testHelper';

const { TextEncoder, TextDecoder } = require('util');
global.TextEncoder = global.TextEncoder || TextEncoder;
global.TextDecoder = global.TextDecoder || TextDecoder;
global.IS_REACT_ACT_ENVIRONMENT = true;

const React = require('react');
const { createRoot } = require('react-dom/client');
const { act } = require('react-dom/test-utils');
const TestUtils = require('react-dom/test-utils');
const DatePicker = require('../../app/assets/javascripts/components/common/date_picker.jsx').default;

// Redux Store
const { Provider } = require('react-redux');
const { createStore, applyMiddleware } = require('redux');
const thunk = require('redux-thunk').default;
const reducer = require('../../app/assets/javascripts/reducers').default;


const renderComponent = (props = {}) => {
    const store = createStore(reducer, applyMiddleware(thunk));

    const container = document.createElement('div');
    document.body.appendChild(container);

    act(() => {
        createRoot(container).render(
            React.createElement(Provider, { store },
                React.createElement(DatePicker, props))
        );
    });

    return container;
}


describe('DatePicker timezone handling', () => {

    test('date-only value (showTime=false) displays the correct day, unshifted', () => {
        // Saved as midnight UTC on April 2nd, like a real timeline_start value from the server
        const savedValue = '2019-04-02T00:00:00.000Z';

        const container = renderComponent({
            id: 'test-date',
            value: savedValue,
            value_key: 'timeline_start',
            editable: true,
            showTime: false,
            onChange: () => { }
        });

        const input = container.querySelector('input.timeline_start');
        // Should show April 2nd, no matter what timezone this test runs under
        expect(input.value).toBe('2019-04-02');
    });

    test('bare "YYYY-MM-DD" value (e.g. a block due_date) displays unshifted in zones ahead of UTC', () => {
        // A plain Rails `date` column value, no time, no timezone attached at all
        const savedValue = '2019-04-02';

        const container = renderComponent({
            id: 'test-due-date',
            value: savedValue,
            value_key: 'due_date',
            editable: true,
            showTime: false,
            onChange: () => { }
        });

        const input = container.querySelector('input.due_date');
        // Should stay April 2nd, even in zones ahead of UTC like Nairobi/Tokyo
        expect(input.value).toBe('2019-04-02');
    });

    test('date-only value (showTime=false): typing a new date sends a UTC value with no local offset', () => {
        let sentValue = null;

        const container = renderComponent({
            id: 'test-date',
            value: '2019-04-02T00:00:00.000Z',
            value_key: 'timeline_start',
            editable: true,
            showTime: false,
            onChange: (key, value) => { sentValue = value; }
        });

        const input = container.querySelector('input.timeline_start');

        act(() => {
            TestUtils.Simulate.change(input, { target: { value: '2019-04-03' } });
        });
        act(() => {
            TestUtils.Simulate.blur(input);
        });

        // Should send April 3rd, locked to UTC, no local timezone offset attached
        expect(sentValue).toBe('2019-04-03T00:00:00.000Z');
    });

    test('timed value (showTime=true) displays the correct local hour, not shifted to UTC', () => {
        // 15:30 UTC on April 2nd -- what this looks like locally depends on the test machine's TZ
        const savedValue = '2019-04-02T15:30:00.000Z';
        const expectedLocalHour = new Date(savedValue).getHours();

        const container = renderComponent({
            id: 'test-timed',
            value: savedValue,
            value_key: 'meetings_timeline_start',
            editable: true,
            showTime: true,
            onChange: () => { }
        });

        const hourSelect = container.querySelector('select.time-input__hour');
        expect(Number(hourSelect.value)).toBe(expectedLocalHour);
    });

    test('timed value (showTime=true): moving the event to another day keeps its time of day', () => {
    let sentValue = null;

    const container = renderComponent({
        id: 'test-timed-move',
        value: '2019-04-02T15:30:00.000Z',
        value_key: 'meetings_timeline_start',
        editable: true,
        showTime: true,
        onChange: (key, value) => { sentValue = value; }
    });

    const input = container.querySelector('input.meetings_timeline_start');

    // Read whatever day is actually showing first, rather than assuming it,
    // since 15:30 UTC can land on a different local calendar day depending
    // on the timezone.
    const currentlyShown = input.value; // e.g. "2019-04-02" or "2019-04-03"
    const [year, month, day] = currentlyShown.split('-').map(Number);

    // Move forward 2 full days, so the move is unambiguous no matter the
    // timezone (moving by 1 day risked accidentally landing back on the
    // same calendar day in some zones).
    const movedDate = new Date(year, month - 1, day + 2);
    const movedDateString = [
        movedDate.getFullYear(),
        String(movedDate.getMonth() + 1).padStart(2, '0'),
        String(movedDate.getDate()).padStart(2, '0')
    ].join('-');

    act(() => {
        TestUtils.Simulate.change(input, { target: { value: movedDateString } });
    });
    act(() => {
        TestUtils.Simulate.blur(input);
    });

    // The time of day (15:30 UTC, whatever that is in local hours/minutes)
    // should be preserved, not reset or shifted.
    const sentDate = new Date(sentValue);
    const original = new Date('2019-04-02T15:30:00.000Z');
    expect(sentDate.getUTCHours()).toBe(original.getUTCHours());
    expect(sentDate.getUTCMinutes()).toBe(original.getUTCMinutes());

    // And the calendar day should have genuinely moved forward by 2 days
    // from whatever day was originally shown.
    expect(input.value).not.toBe(currentlyShown);
});
});
