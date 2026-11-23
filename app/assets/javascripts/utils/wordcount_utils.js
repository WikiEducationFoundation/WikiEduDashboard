// Rounds down, like WordCount.from_characters on the server, so a student's
// or article's words match the CSVs and course totals.
export const bytesToWords = (bytes, bytesPerWord) => {
  return Math.floor(bytes / bytesPerWord);
};
