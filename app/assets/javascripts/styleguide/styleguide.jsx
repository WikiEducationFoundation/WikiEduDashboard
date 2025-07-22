/* eslint-disable no-console */

import React from 'react';
import createReactClass from 'create-react-class';
import TextAreaInput from '../components/common/text_area_input';
import DatePicker from '../components/common/date_picker.jsx';
import Calendar from '../components/common/calendar.jsx';
import Popover from '../components/common/popover.jsx';
import Loading from '../components/common/loading.jsx';
import { createRoot } from 'react-dom/client';

const StyleguideExamples = {

  datePickerEnabled() {
    const root = createRoot(document.getElementById('date-picker-enabled'));
    root.render(
      <DatePicker
        editable
        value_key="start"
        label="Start Date"
        date_props={{ minDate: '2016-06-10', maxDate: '2016-06-29' }}
        onChange={(key, date) => { console.log(key, date); }}
        value="2016-06-22"
        placeholder="Please choose a date"
      />
    );
  },

  datePickerDisabled() {
    const root = createRoot(document.getElementById('date-picker-disabled'));
    root.render(
      <DatePicker
        value_key="start"
        label="Start Date"
        date_props={{ minDate: '2016-06-10', maxDate: '2016-06-29' }}
        onChange={(key, date) => { console.log(key, date); }}
        value="2016-06-22"
        placeholder="Please choose a date"
      />
    );
  },

  calendar() {
    const root = createRoot(document.getElementById('calendar'));
    root.render(
      <Calendar
        course={{ start: '2016-06-01', end: '2016-06-30' }}
        editable={true}
        calendarInstructions="Edit the dates of your course"
        updateCourse={() => { return null; }}
      />
    );
  },

  richText() {
    const root = createRoot(document.getElementById('rich-text'));
    root.render(
      <TextAreaInput
        value="Lorem ipsum dolor sit amet, consectetur adipiscing elit."
        editable={true}
        onChange={() => { return null; }}
        wysiwyg={true}
      />
    );
  },

  popover() {
    const PopoverExample = createReactClass({
      getInitialState() {
        return {
          open: false
        };
      },

      toggleOpen() {
        this.setState({
          open: !this.state.open
        });
      },

      render() {
        const editRow = (
          <tr className="edit">
            <td>&quot;Edit row&quot; content: Lorem ipsum dolor sit amet.</td>
          </tr>
        );

        const rows = (
          <tr>
            <td>&quot;Rows&quot; content: Lorem ipsum dolor sit amet.</td>
          </tr>
        );

        return (
          <div className="pop__container">
            <button className="button dark" onClick={this.toggleOpen}>Toggle popover</button>
            <Popover
              is_open={this.state.open}
              edit_row={editRow}
              rows={rows}
            />
          </div>
        );
      }
    });
    const root = createRoot(document.getElementById('popover'));
    root.render(<PopoverExample />);
  },

  loading() {
    const root = createRoot(document.getElementById('loading'));

    root.render(<Loading />);
  }
};

$(() => {
  Object.keys(StyleguideExamples).forEach((example) => {
    StyleguideExamples[example]();
  });
});
