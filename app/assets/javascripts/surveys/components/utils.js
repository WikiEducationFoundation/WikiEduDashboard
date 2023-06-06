export function answerTotals(question) {
  const optionTotals = {};
  question.answer_options.forEach((option) => {
    let count = 0;
    question.answers.forEach((answer) => {
      if (option === answer) {
        count += 1;
      }
    });
    optionTotals[option] = count;
  });
  return optionTotals;
}

export function answerFrequency(answers) {
  const counts = {};
  answers.forEach((answer) => {
    if (counts[answer] === undefined) {
      counts[answer] = 1;
    } else {
      counts[answer] += 1;
    }
  });
  return counts;
}
