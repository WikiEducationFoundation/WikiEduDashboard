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
      width: '100%',
      marginTop: '0px',
      marginBottom: '8px',
    }),
    menuPortal: (styles, { rect }) => {
      const viewportWidth = typeof window !== 'undefined' ? window.innerWidth : 1024;
      const menuWidth = Math.min(170, viewportWidth - 16);

      const left = Math.max(
        8,
        Math.min(
          rect.left + rect.width - menuWidth,
          viewportWidth - menuWidth - 8
        )
      );

      return {
        ...styles,
        left,
        width: `${menuWidth}px`,
        zIndex: 9999,
      };
    },
    container: styles => ({
      ...styles,
      width: '60px',
      height: '35px',
    }),
  };

  export default sortSelectStyles;
