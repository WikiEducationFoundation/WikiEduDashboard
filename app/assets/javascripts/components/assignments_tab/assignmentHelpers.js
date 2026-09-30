import { format, parseISO } from 'date-fns';

// Labels come from existing translations wherever one fits: the Canvas
// assignment views already name most of these things.
const KIND_LABELS = {
  training: 'training.kind.training',
  exercise: 'training.kind.exercise',
  article: 'assignments.article_link',
  peer_review: 'assignments.peer_review_link',
};

export const STATE_LABELS = {
  complete: 'lti.assignment_view.status.completed',
  in_progress: 'lti.assignment_view.status.in_progress',
  not_started: 'lti.assignment_view.status.not_started',
};

export const FILTERS = ['all', 'complete', 'in_progress', 'not_started', 'overdue'];

export const itemTitle = (item) => {
  if (item.title) { return item.title; }
  if (item.kind === 'peer_review') { return I18n.t('lti.status.roster.peer_reviews'); }
  return I18n.t('lti.assignment_view.roster.assigned_article');
};

export const kindLabel = item => I18n.t(KIND_LABELS[item.kind]);

export const stateLabel = state => I18n.t(STATE_LABELS[state]);

export const filterLabel = (filter) => {
  if (filter === 'all') { return I18n.t('articles.filter.wiki_all'); }
  if (filter === 'overdue') { return I18n.t('assignments_tab.overdue'); }
  return stateLabel(filter);
};

export const matchesFilter = (cell, filter) => {
  if (!filter || filter === 'all') { return true; }
  if (filter === 'overdue') { return Boolean(cell?.overdue); }
  return cell?.state === filter;
};

// Dates arrive as ISO strings; a bare date ("2026-02-14") is a local date,
// which parseISO keeps (new Date() would read it as UTC midnight).
export const formatDate = iso => (iso ? format(parseISO(iso), 'MMM d, yyyy') : null);

// Finished after the end of the due date.
export const isLate = (completedAt, dueDate) => {
  if (!completedAt || !dueDate) { return false; }
  return parseISO(completedAt) > new Date(`${dueDate}T23:59:59`);
};

export const percent = fraction => `${Math.round(fraction * 100)}%`;

// "Real Name (username)" when the viewer may see real names, as the Students
// tab and the claim-verification responses identify students.
export const studentName = ({ username, real_name: realName }) => (
  realName ? `${realName} (${username})` : username
);

// A pipeline status's label, or nothing for a status without one.
export const articleStatusLabel = status => (
  status ? I18n.t(`article_statuses.${status}`, { defaultValue: '' }) : ''
);

// Where `username` sits in `students`, and who comes before and after it.
export const neighbors = (students, username) => {
  const index = students.findIndex(student => student.username === username);
  if (index === -1) { return { index, previous: null, next: null }; }
  return {
    index,
    previous: students[index - 1] || null,
    next: students[index + 1] || null,
  };
};
