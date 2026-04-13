import './utils/editable';

document.addEventListener('DOMContentLoaded', () => {
  const toggleAdvancedSearchBtn = document.getElementById('toggle_advanced_search');
  const advancedSearchFields = document.getElementById('advanced_search_fields');

  if (toggleAdvancedSearchBtn && advancedSearchFields) {
    toggleAdvancedSearchBtn.addEventListener('click', () => {
      advancedSearchFields.classList.toggle('hidden');
      const icon = toggleAdvancedSearchBtn.querySelector('.icon');
      if (icon) {
        if (advancedSearchFields.classList.contains('hidden')) {
          icon.classList.remove('icon-arrow-up');
          icon.classList.add('icon-arrow-down');
        } else {
          icon.classList.remove('icon-arrow-down');
          icon.classList.add('icon-arrow-up');
        }
      }
    });
  }

  if (typeof TomSelect !== 'undefined') {
    // eslint-disable-next-line no-new
    new TomSelect('#school_select', {
      plugins: ['remove_button'],
      placeholder: `${I18n.t('assignments.select')} ${I18n.t('courses_generic.creator.course_school')}...`,
      allowEmptyOption: true
    });
  }

  const isLatin = ['es', 'pt'].some(l => locale.startsWith(l));
  const currentLocale = locale.split('-')[0];
  const dateFormat = isLatin ? 'd/m/Y' : 'm/d/Y';

  const setupRangePicker = (rangeSelector, startSelector, endSelector) => {
    const startInput = document.querySelector(startSelector);
    const endInput = document.querySelector(endSelector);
    const startVal = startInput.value;
    const endVal = endInput.value;
    const defaultDate = (startVal && endVal) ? [startVal, endVal] : null;

    flatpickr(rangeSelector, {
      mode: 'range',
      altInput: true,
      altFormat: dateFormat,
      dateFormat: 'Y-m-d',
      defaultDate,
      locale: isLatin ? currentLocale : 'default',
      allowInput: true,
      onClose(selectedDates, dateStr, instance) {
        if (selectedDates.length === 2) {
          startInput.value = instance.formatDate(selectedDates[0], 'Y-m-d');
          endInput.value = instance.formatDate(selectedDates[1], 'Y-m-d');
        } else {
          startInput.value = '';
          endInput.value = '';
        }
      }
    });
  };

  setupRangePicker('#creation_date_range', '#creation_start', '#creation_end');
  setupRangePicker('#start_date_range', '#start_date_start', '#start_date_end');

  document.querySelector('#clear_filters')?.addEventListener('click', () => {
    const form = document.getElementById('campaign_search_form');
    const fields = form.querySelectorAll('input:not([type="hidden"])');
    fields.forEach((field) => {
      field.value = '';
    });
    const hiddenFields = ['creation_start', 'creation_end', 'start_date_start', 'start_date_end'];
    hiddenFields.forEach((id) => {
      const el = document.getElementById(id);
      if (el) el.value = '';
    });
    const schoolSelect = document.getElementById('school_select');
    if (schoolSelect?.tomselect) {
      schoolSelect.tomselect.clear();
    }
    form.action = `${form.action.replace(/#.*$/, '')}#courses_table`;
    form.submit();
  });
});
