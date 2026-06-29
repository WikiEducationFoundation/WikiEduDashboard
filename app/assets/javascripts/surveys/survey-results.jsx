import React from 'react';
import QuestionResults from './components/QuestionResults.jsx';
import { createRoot } from 'react-dom/client';

document.querySelectorAll('[data-question-results]').forEach((el) => {
  const dataAttr = el.getAttribute('data-question-results') || '{}';
  const data = JSON.parse(dataAttr);

  const root = createRoot(el);
  root.render(<QuestionResults {...data} />);
});
