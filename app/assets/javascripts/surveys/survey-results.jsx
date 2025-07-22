import React from 'react';
import QuestionResults from './components/QuestionResults.jsx';
import { createRoot } from 'react-dom/client';

$('[data-question-results]').each((i, result) => {
  const data = $(result).data('question-results');
  const root = createRoot(result);
  root.render(<QuestionResults {...data} />);
});
