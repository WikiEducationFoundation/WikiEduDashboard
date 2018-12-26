import React from 'react';
import ReactDOM from 'react-dom';
import QuestionResults from './components/QuestionResults.jsx';
window.$ = require('jquery');

$('[data-question-results]').each((i, result) => {
  const data = $(result).data('question-results');
  ReactDOM.render(<QuestionResults {...data} />, result);
});
