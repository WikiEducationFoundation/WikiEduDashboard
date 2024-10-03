// Formats the  date and returns it in the format YYYYMMDD
const pageViewDateString = (date) => {
  return date.toJSON().slice(0, 10).replace(/-/g, '');
};
export default pageViewDateString;
