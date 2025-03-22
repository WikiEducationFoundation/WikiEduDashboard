import { http, HttpResponse } from 'msw';

export const adminCourseNotesHandlers = [
  http.get('/admin_course_notes/:courseId', () => {
    return HttpResponse.json({
      AdminCourseNotes: [{
        id: '13',
        courses_id: '10002',
        text: 'A supporting character in The Lord of the Rings, and the fictional narrator of many of Tolkien\'s Middle-earth writings.',
        title: 'Bilbo baggins',
        edited_by: 'Tolkien',
        created_at: '2024-05-06T08:12:21.092Z',
        updated_at: '2025-02-23T15:04:38.802Z'
      }]
    });
  }),
  http.post('/admin_course_notes', async ({ request }) => {
    const newPost = await request.json();
    return HttpResponse.json({
      created_admin_course_note: {
        id: 'new-note-id',
        course_id: '10002',
        ...newPost,
        created_at: '2025-03-01T00:00:00Z',
        updated_at: '2025-03-01T00:00:00Z'
      }
    });
  }),
  http.delete('/admin_course_notes/:adminCourseNoteId', () => {
    return HttpResponse.json({ success: true });
  }),
  http.put('/admin_course_notes/:adminCourseNoteId', () => {
    return HttpResponse.json({ success: true });
  })
];
