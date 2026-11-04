

import i18n from '../i18n';
import React from 'react';
import createReactClass from 'create-react-class';
import TextAreaInput from '../components/common/text_area_input';
import DatePicker from '../components/common/date_picker.jsx';
import Calendar from '../components/common/calendar.jsx';
import Popover from '../components/common/popover.jsx';
import Loading from '../components/common/loading.jsx';
import { createRoot } from 'react-dom/client';
import { Provider } from 'react-redux';
import { configureStore } from '@reduxjs/toolkit';
import { parseISO } from 'date-fns';
import validations from '../reducers/validations';

const store = configureStore({ reducer: { validations } });

const renderExample = (id, example) => {
  const root = createRoot(document.getElementById(id));
  root.render(<Provider store={store}>{example}</Provider>);
};

const StyleguideExamples = {

  datePickerEnabled() {
    renderExample('date-picker-enabled',
      <DatePicker
        editable
        value_key="start"
        label="Start Date"
        date_props={{
          minDate: parseISO('2016-06-10'),
          maxDate: parseISO('2016-06-29')
        }}
        onChange={(key, date) => { console.log(key, date); }}
        value="2016-06-22"
        placeholder="Please choose a date"
      />
    );
  },

  datePickerDisabled() {
    renderExample('date-picker-disabled',
      <DatePicker
        value_key="start"
        label="Start Date"
        date_props={{
          minDate: parseISO('2016-06-10'),
          maxDate: parseISO('2016-06-29')
        }}
        onChange={(key, date) => { console.log(key, date); }}
        value="2016-06-22"
        placeholder="Please choose a date"
      />
    );
  },

  calendar() {
    renderExample('calendar',
      <Calendar
        course={{ start: '2016-06-01', end: '2016-06-30' }}
        editable={true}
        calendarInstructions="Edit the dates of your course"
        updateCourse={() => { return null; }}
      />
    );
  },

  richText() {
    renderExample('rich-text',
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
            <button type="button" className="button dark" onClick={this.toggleOpen}>Toggle popover</button>
            <Popover
              is_open={this.state.open}
              edit_row={editRow}
              rows={rows}
            />
          </div>
        );
      }
    });
    renderExample('popover', <PopoverExample />);
  },

  loading() {
    renderExample('loading', <Loading />);
  }
};

document.addEventListener('DOMContentLoaded', () => {
  i18n.defaultLocale = window.defaultLocale;
  i18n.locale = window.locale;
  i18n.availableLocales = window.availableLocales;
  i18n.store(window.stores || {});
  Object.keys(StyleguideExamples).forEach((example) => {
    StyleguideExamples[example]();
  });
});
