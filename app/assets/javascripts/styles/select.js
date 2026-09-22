const selectStyles = {
  option: (styles, { isFocused }) => {
    return {
      ...styles,
      color: isFocused ? 'white' : '#666',
      backgroundColor: isFocused ? '#676EB4' : null,
    };
  },
  control: (base, { isFocused }) => ({
    ...base,
    borderColor: isFocused ? '#676EB4' : base.borderColor,
    '&:hover': { borderColor: '#676EB4' },
    boxShadow: 'none'
  }),
  singleValue: base => ({
    ...base,
    padding: '0px 10px',
    fontSize: 'larger',
    border: '2px solid #D9D9D9',
    backgroundColor: '#F2F2F2'
  }),
  multiValue: base => ({
    ...base,
    fontSize: 'larger',
    border: '2px solid #D9D9D9',
    backgroundColor: '#F2F2F2'
  }),
  multiValueRemove: base => ({
    ...base,
    color: '#676EB4',
    backgroundColor: '#F2F2F2',
    borderRadius: 0,
    '&:hover': { backgroundColor: '#D9D9D9', color: '#676EB4' }
  })
};

// Smaller dropdown arrow and tighter padding, for selects inside table rows.
export const compactIndicatorStyles = {
  dropdownIndicator: base => ({
    ...base,
    padding: '0 4px',
    svg: { width: 14, height: 14 }
  }),
  indicatorSeparator: base => ({ ...base, marginTop: 6, marginBottom: 6 }),
  valueContainer: base => ({ ...base, padding: '2px 6px' })
};

export default selectStyles;
