// Shows and hides the apply form's conditional questions as answers change,
// following the same rules as RapidfireConditionals on the server
// (lib/rapidfire_conditionals.rb), which in turn follows Survey.js.
// Fields in a hidden question are disabled, so the browser neither validates
// nor submits them.

const COMPARISONS = {
  '<': (a, b) => a < b,
  '<=': (a, b) => a <= b,
  '>': (a, b) => a > b,
  '>=': (a, b) => a >= b,
};

// The admin UI stores conditional values with spaces as underscores and
// quotes as HTML entities.
const normalize = (string) => {
  const decoder = document.createElement('textarea');
  decoder.innerHTML = string;
  return decoder.value.trim().split(' ').join('_');
};

const parseConditional = (string) => {
  const [questionId, operator, value = ''] = string.split('|');
  return { questionId, operator, value };
};

const answersFor = (container) => {
  const fields = container.querySelectorAll('input, select, textarea');
  return Array.from(fields)
    .filter(field => !field.name.includes('follow_up_answer_text'))
    .filter(field => !['radio', 'checkbox'].includes(field.type) || field.checked)
    .map(field => field.value.trim())
    .filter(value => value !== '');
};

const conditionMet = ({ operator, value }, answers) => {
  if (operator === '*presence') return answers.length > 0;
  if (COMPARISONS[operator]) {
    const answer = parseInt(answers[0]);
    return !Number.isNaN(answer) && COMPARISONS[operator](answer, parseInt(value));
  }
  return answers.some(answer => normalize(answer) === normalize(value));
};

const setVisible = (question, visible) => {
  question.hidden = !visible;
  question.querySelectorAll('input, select, textarea').forEach((field) => {
    field.disabled = !visible;
  });
};

// A conditional can depend on a question that is itself conditional, so this
// repeats until nothing changes.
const updateConditionals = (form) => {
  const questions = Array.from(form.querySelectorAll('[data-conditional]'));
  for (let pass = 0; pass <= questions.length; pass += 1) {
    let changed = false;
    questions.forEach((question) => {
      const conditional = parseConditional(question.dataset.conditional);
      const parent = document.getElementById(`question_${conditional.questionId}`);
      const visible = Boolean(parent) && !parent.hidden
        && conditionMet(conditional, answersFor(parent));
      if (question.hidden === visible) {
        setVisible(question, visible);
        changed = true;
      }
    });
    if (!changed) return;
  }
};

document.addEventListener('DOMContentLoaded', () => {
  const form = document.querySelector('[data-course-application-form]');
  if (!form) return;
  form.addEventListener('input', () => updateConditionals(form));
  form.addEventListener('change', () => updateConditionals(form));
  updateConditionals(form);
});
