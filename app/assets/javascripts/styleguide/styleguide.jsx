/* eslint-disable no-console */

import React from 'react';
import ReactDOM from 'react-dom';
import TrixEditor from 'react-trix';
import DatePicker from '../components/common/date_picker.jsx';
import Calendar from '../components/common/calendar.cjsx';

const StyleguideExamples = {

  datePickerEnabled() {
    ReactDOM.render((
      <DatePicker
        editable
        value_key="start"
        label="Start Date"
        date_props={{ minDate: '2016-06-10', maxDate: '2016-06-29' }}
        onChange={(key, date) => {console.log(key, date);}}
        value="2016-06-22"
        placeholder="Please choose a date"
      />
    ), document.getElementById('date-picker-enabled'));
  },

  datePickerDisabled() {
    ReactDOM.render((
      <DatePicker
        value_key="start"
        label="Start Date"
        date_props={{ minDate: '2016-06-10', maxDate: '2016-06-29' }}
        onChange={(key, date) => {console.log(key, date);}}
        value="2016-06-22"
        placeholder="Please choose a date"
      />
    ), document.getElementById('date-picker-disabled'));
  },

  calendar() {
    ReactDOM.render((
      <Calendar
        course={{ start: '2016-06-01', end: '2016-06-30' }}
        editable={true}
        calendarInstructions="Edit the dates of your course"
      />
    ), document.getElementById('calendar'));
  },

  richText() {
    ReactDOM.render((
      <TrixEditor
        value="Lorem ipsum dolor sit amet, consectetur adipiscing elit."
        onChange={(e) => {console.log(e);}}
      />
    ), document.getElementById('rich-text'));
  }
};

$(() => {
  for (const example in StyleguideExamples) {
    if (StyleguideExamples.hasOwnProperty(example)) {
      StyleguideExamples[example]();
    }
  }
});
