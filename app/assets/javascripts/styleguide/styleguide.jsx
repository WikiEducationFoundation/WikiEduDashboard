/* eslint-disable no-console */

import React from 'react';
import ReactDOM from 'react-dom';
import DatePicker from '../components/common/date_picker.jsx';

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
  }
};

$(() => {
  for (const example in StyleguideExamples) {
    if (StyleguideExamples.hasOwnProperty(example)) {
      StyleguideExamples[example]();
    }
  }
});
