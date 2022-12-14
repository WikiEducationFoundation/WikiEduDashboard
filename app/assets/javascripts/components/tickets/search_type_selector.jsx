import React, { forwardRef } from 'react';
import Select from 'react-select';
import selectStyles from '../../styles/single_select';

const SearchTypeSelector = ({ handleChange, value }, ref) => {
  const options = [
    { value: 'no_search', label: 'No search' },
    { value: 'by_email_or_username', label: 'Search by email or user name' },
    { value: 'in_content', label: 'Search in content' },
    { value: 'in_subject', label: 'Search in subject' }
  ];

  return (
    <div className="form-group">
      <label htmlFor="search_type_selector">{I18n.t('tickets.chose_search_type')}:</label>
      <Select
        id="search_type_selector"
        instanceId="search-type"
        value={options.find(elmnt => elmnt.value === value)}
        onChange={handleChange}
        options={options}
        ref={ref}
        simpleValue
        styles={selectStyles}
      />
    </div>
  );
};

export default forwardRef(SearchTypeSelector);
