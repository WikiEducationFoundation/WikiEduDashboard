import React from 'react';
import QuestionResults from './components/QuestionResults.jsx';
import { createRoot } from 'react-dom/client';

document.addEventListener('DOMContentLoaded', () => {
  const resultElements = document.querySelectorAll('[data-question-results]');
  resultElements.forEach((el) => {
    const dataAttr = el.getAttribute('data-question-results');
    let data = {};

    try {
      data = JSON.parse(dataAttr);
    } catch (e) {
      console.error('Invalid JSON in data-question-results:', e);
    }

    const root = createRoot(el);
    root.render(<QuestionResults {...data} />);
  });
});
