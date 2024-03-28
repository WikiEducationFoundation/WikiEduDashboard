import React, { useEffect } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import { fetchAllCourseNotes } from '../../actions/course_notes_action';
import NotesPanelEditButton from './notes_panel_edit_button';
import NotesList from './notes_list';

const NotesPanel = ({ setState, modalType, courseId, buttonText, headerText }) => {
  const notesList = useSelector(state => state.courseNotes.notes_list);
  const dispatch = useDispatch();

  useEffect(() => {
    const fetchData = () => {
      dispatch(fetchAllCourseNotes(courseId));
    };

    fetchData();

    // Set up a polling interval to fetch data periodically (every 60 seconds)
    const pollInterval = setInterval(fetchData, 60000);

    return () => clearInterval(pollInterval);
  }, []);

  // Conditionally render a button if modalType is null
  if (modalType === null) {
    return <button onClick={() => setState(null)} className="button">{I18n.t(buttonText)}</button>;
  }

  return (
    <div className="basic-modal">
      <button onClick={() => setState(undefined, null)} className="pull-right article-viewer-button icon-close" />
      <div className="list__wrapper">
        <div className="section-header">
          <h3>{I18n.t(headerText)}</h3>
        </div>
        <div className="users-control" style={{ marginBottom: '30px' }}>
          <NotesPanelEditButton setState={setState} notesList={notesList} />
        </div>
        <NotesList setState={setState} courseId={courseId} notesList={notesList}/>
      </div>
    </div>
   );
};

export default NotesPanel;
