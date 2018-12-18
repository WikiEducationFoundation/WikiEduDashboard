const selectStyles = {
    option: (styles, { isFocused }) => {
      return {
        ...styles,
        color: isFocused ? 'white' : null,
        backgroundColor: isFocused ? '#676EB4' : null,
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
