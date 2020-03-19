import React from 'react';
import { bytesToWords } from '~/app/assets/javascripts/utils/wordcount_utils';

const ContentAdded = ({ student, course }) => {
  if (course.home_wiki_bytes_per_word) {
    const mainspaceWords = bytesToWords(student.character_sum_ms, course.home_wiki_bytes_per_word);
    const userspaceWords = bytesToWords(student.character_sum_us, course.home_wiki_bytes_per_word);
    const draftWords = bytesToWords(student.character_sum_draft, course.home_wiki_bytes_per_word);
    return (
      <td className="desktop-only-tc">
        {mainspaceWords} | {userspaceWords} | {draftWords}
      </td>
    );
  }
  return (
    <td className="desktop-only-tc">
      {student.character_sum_ms} | {student.character_sum_us} | {student.character_sum_draft}
    </td>
  );
};

export default ContentAdded;
