
const UIActionsRedux = {
  toggleOpen: function (key) {
    return {
      type: 'OPEN_KEY',
      data: { key }
    };
  }
};

export default UIActionsRedux;
