const sortSelectStyles = {
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
      fontSize: '14px',
      minHeight: '1.2em',
      paddingLeft: '20px',
      paddingTop: '4px',
      paddingRight: '5px',
      paddingBottom: '4px',
    };
  },
  control: base => ({
    ...base,
    opacity: '0',
    width: '60px',
    height: '35px',
    backgroundColor: 'red',
    cursor: 'pointer',

  }),
  menu: styles => ({
    ...styles,
    width: '170px',
    position: 'relative',
    top: '0%',
    left: '50%',
    right: '0%',
    transform: 'translate(-50%)',
    marginTop: '0px',
    marginBottom: '8px',
  }),
  container: styles => ({
    ...styles,
    width: '60px',
    height: '35px',
  }),
};

export default sortSelectStyles;
