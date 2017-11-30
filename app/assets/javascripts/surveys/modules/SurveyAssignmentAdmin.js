const { List } = window;

const SurveyAssignmentAdmin = {
  init() {
    this.sortableTables();
    return this.listeners();
  },

  listeners() {
    return $('[data-toggle-courses-table]').on('click', $.proxy(this, 'toggleCoursesTable'));
  },

  sortableTables() {
    return $('[data-sortable-courses]').each((i, sortableCourses) => {
      const options =
        { valueNames: ['title', 'id'] };

      return new List(sortableCourses, options);
    });
  },

  toggleCoursesTable({ target }) {
    return $(target).parents('.block').find('[data-sortable-courses]').toggleClass('active');
  }
};

export default SurveyAssignmentAdmin;
