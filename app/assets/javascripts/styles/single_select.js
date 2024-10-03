const selectStyles = {
  option: (styles, { isDisabled, isFocused, isSelected }) => {
    let backgroundColor;
    let color;
    if (isDisabled) {
      backgroundColor = null;
    } else if (isSelected) {
      backgroundColor = '#676EB4';
    } else if (isFocused) {
      backgroundColor = 'rgba(103, 110, 180, 0.15)';
    } else {
      backgroundColor = 'white';
    }
    if (isDisabled) {
      color = '#ccc';
    } else if (isSelected) {
      color = 'white';
    } else {
      color = 'black';
    }

    return {
      ...styles,
      backgroundColor,
      color,
      cursor: isDisabled ? 'not-allowed' : 'default',
    };
  },
  control: (base, { isFocused }) => ({
    ...base,
    borderColor: isFocused ? '#676EB4' : base.borderColor,
    '&:hover': { borderColor: '#676EB4' },
    boxShadow: 'none'
  }),
};

export default selectStyles;
