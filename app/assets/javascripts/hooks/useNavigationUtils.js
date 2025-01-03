import { useNavigate } from 'react-router-dom';

const useNavigationsUtils = () => {
  const navigate = useNavigate();

  const openStudentDetailsView = (courseSlug, studentUsername) => {
    const url = `/courses/${courseSlug}/students/articles/${encodeURIComponent(studentUsername)}`;
    navigate(url);
  };

  return {
    openStudentDetailsView,
  };
};

export default useNavigationsUtils;
