const Utils = {
  parseConditionalString(string) {
    const params = string.split('|');
    return ({} = {
      question_id: params[0],
      operator: params[1],
      value: params[2].trim().split(' ').join('_'),
      multi: params[3] === 'multi'
    });
  },

  toTitleCase(str) {
    return str.replace(/\w\S*/g, txt => txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase());
  }
};

export default Utils;
