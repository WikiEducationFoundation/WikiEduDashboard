const { List } = window;

const SurveyAssignmentAdmin = {
  init() {
    this.sortableTables();
    this.listeners();
  },

  listeners() {
    document.querySelectorAll('[data-toggle-courses-table]').forEach(button => {
      button.addEventListener('click', (e) => this.toggleCoursesTable(e));
    });
  },

  sortableTables() {
    document.querySelectorAll('[data-sortable-courses]').forEach(sortableCourses => {
      const options = {
        valueNames: ['title', 'id']
      };
      new List(sortableCourses, options);
    });
  },

    toggleCoursesTable(event) {
    const target = event.currentTarget;
    // Find the closest parent with .block and toggle the active class on the data-sortable-courses element inside
    const block = target.closest('.block');
    const table = block?.querySelector('[data-sortable-courses]');
    if (table) {
      table.classList.toggle('active');
    }
  }
};

export default SurveyAssignmentAdmin;
