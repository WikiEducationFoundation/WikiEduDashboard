import { apiSlice } from '@components/util/apiSlice';
import { ADD_NOTIFICATION } from '../constants/notifications';

export const apiSliceWithAdminCourseNotes = apiSlice.injectEndpoints({
  endpoints: builder => ({
    // CREATE
    createAdminCourseNote: builder.mutation({
      query: adminCourseNoteDetails => ({
        url: '/admin_course_notes',
        method: 'POST',
        body: adminCourseNoteDetails
      }),

      onQueryStarted: async (adminCourseNoteDetails, { dispatch, queryFulfilled }) => {
        const { courses_id: courseId } = adminCourseNoteDetails;
        const timestamp = new Date().toISOString();

        // Optimistically update cache with temp note i.e newly created note
        const optimisticUpdate = dispatch(
          apiSliceWithAdminCourseNotes.util.updateQueryData('fetchAllAdminCourseNotes', courseId, (draft) => {
            draft.AdminCourseNotes.push({
              ...adminCourseNoteDetails,
              id: 'temp-id',
              created_at: timestamp,
              updated_at: timestamp,
            });
          })
        );

        try {
          // Wait for the API call to complete successfully
          const { data: response } = await queryFulfilled;

          // Replace temp note with actual server response
          dispatch(
            apiSliceWithAdminCourseNotes.util.updateQueryData('fetchAllAdminCourseNotes', courseId, (draft) => {
              const tempIndex = draft.AdminCourseNotes.findIndex(note => note.id === 'temp-id');
              if (tempIndex !== -1) {
                draft.AdminCourseNotes[tempIndex] = response.created_admin_course_note;
              }
            })
          );

          sendNotification(dispatch, 'Success', 'notes.created');
        } catch {
          // If the API call fails, undo the optimistic update
          optimisticUpdate.undo();
          sendNotification(dispatch, 'Error', 'notes.failure');
        }
      },
    }),

    // READ
    fetchAllAdminCourseNotes: builder.query({ query: courseId => `/admin_course_notes/${courseId}` }),

    // UPDATE
    saveUpdatedAdminCourseNote: builder.mutation({
      query: adminCourseNoteDetails => ({
        url: `/admin_course_notes/${adminCourseNoteDetails.id}`,
        method: 'PUT',
        body: adminCourseNoteDetails
      }),

      onQueryStarted: async (adminCourseNoteDetails, { dispatch, queryFulfilled, getState }) => {
        const { id: courseId } = getState().course;

        // Optimistically update the cache i.e Update the respective note
        const optimisticUpdate = dispatch(
          apiSliceWithAdminCourseNotes.util.updateQueryData('fetchAllAdminCourseNotes', courseId, (draft) => {
            const tempIndex = draft.AdminCourseNotes.findIndex(note => note.id === adminCourseNoteDetails.id);
            if (tempIndex !== -1) {
              draft.AdminCourseNotes[tempIndex] = {
                ...draft.AdminCourseNotes[tempIndex],
                ...adminCourseNoteDetails,
                updated_at: new Date().toISOString(),
              };
            }
          })
        );

        try {
          // Wait for the API call to complete successfully
          await queryFulfilled;
          sendNotification(dispatch, 'Success', 'notes.updated');
        } catch {
          // If the API call fails, undo the optimistic update
          optimisticUpdate.undo();
          sendNotification(dispatch, 'Error', 'notes.failure');
        }
      }
    }),

    // DELETE
    deleteAdminCourseNote: builder.mutation({
      query: adminCourseNoteId => ({
        url: `/admin_course_notes/${adminCourseNoteId}`,
        method: 'DELETE'
      }),

      onQueryStarted: async (adminCourseNoteId, { dispatch, queryFulfilled, getState }) => {
        const { id: courseId } = getState().course;

        // Optimistically update the cache i.e Remove the deleted note from the cache
        const optimisticUpdate = dispatch(
          apiSliceWithAdminCourseNotes.util.updateQueryData('fetchAllAdminCourseNotes', courseId, (draft) => {
            draft.AdminCourseNotes = draft.AdminCourseNotes.filter(note => note.id !== adminCourseNoteId);
          })
        );

        try {
          // Wait for the API call to complete successfully
          await queryFulfilled;
          sendNotification(dispatch, 'Success', 'notes.deleted');
        } catch {
          // If the API call fails, undo the optimistic update
          optimisticUpdate.undo();
          sendNotification(dispatch, 'Error', 'notes.delete_note_error');
        }
      }
    })
  }),
});

// Helper function for notifications
export const sendNotification = (dispatch, type, messageKey, dynamicValue) => {
  const notificationConfig = {
    message: I18n.t(messageKey, dynamicValue),
    closable: true,
    type: type === 'Success' ? 'success' : 'error',
  };

  dispatch({ type: ADD_NOTIFICATION, notification: notificationConfig });
  return notificationConfig.type;
};

export const {
  useFetchAllAdminCourseNotesQuery,
  useCreateAdminCourseNoteMutation,
  useDeleteAdminCourseNoteMutation,
  useSaveUpdatedAdminCourseNoteMutation
} = apiSliceWithAdminCourseNotes;
