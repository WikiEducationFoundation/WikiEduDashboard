import React from 'react';
import { screen, waitFor, fireEvent } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import NotesPanel from '../../../app/assets/javascripts/components/admin_notes/notes_panel';
import Confirm from '../../../app/assets/javascripts/components/common/confirm';
import { sendNotification } from '../../../app/assets/javascripts/slices/AdminCourseNotesSlice';
import { renderWithProviders } from '../../ReduxTestUtils';

jest.mock('../../../app/assets/javascripts/slices/AdminCourseNotesSlice', () => ({
  ...jest.requireActual('../../../app/assets/javascripts/slices/AdminCourseNotesSlice'),
  sendNotification: jest.fn()
}));

describe('NotesPanel Component', () => {
  // Test initial render state
  test('renders a button that opens the notes panel', async () => {
    renderWithProviders(<NotesPanel current_user={{ username: 'testuser' }} />);
    // Find and click the button to open the panel
    const openButton = await screen.findByRole('button');
    expect(openButton).toBeInTheDocument();

    userEvent.click(openButton);

    await waitFor(() => {
      expect(screen.getByText('notes.admin.header_text')).toBeInTheDocument();
    });
  });

  // Test main functionality of the panel when open
  test('displays notes and allows for note creation', async () => {
    // Find and click the button
    renderWithProviders(<NotesPanel current_user={{ username: 'testuser' }} />);

    // Open the panel
    const openButton = await screen.findByRole('button');
    expect(openButton).toBeInTheDocument();
    userEvent.click(openButton);

    // Panel header should be visible
    await waitFor(() => {
      expect(screen.getByText('notes.admin.header_text')).toBeInTheDocument();
    });

    // Should have a button to create a new note
    const createButton = screen.getByLabelText('notes.admin.aria_label.create_note');
    expect(createButton).toBeInTheDocument();

    // Click to create a new note
    userEvent.click(createButton);

    //  Should now display input fields for title and text
    await waitFor(() => {
      expect(screen.getByText('notes.cancel_note_creation')).toBeInTheDocument();
      expect(screen.getByText('notes.post_note')).toBeInTheDocument();
      expect(screen.getByPlaceholderText('notes.note_title')).toBeInTheDocument();
      expect(screen.getByPlaceholderText('notes.note_text')).toBeInTheDocument();
    });

    // Should also display aria label action buttons for post and cancel for screen reader
    expect(screen.getByLabelText('notes.admin.aria_label.post_created_note')).toBeInTheDocument();
    expect(screen.getByLabelText('notes.admin.aria_label.cancel_note_creation')).toBeInTheDocument();
  });

  // Test closing the panel
  test('can close the notes panel', async () => {
    renderWithProviders(<NotesPanel current_user={{ username: 'testuser' }} />);

    // Open the panel
    const openButton = await screen.findByRole('button');
    userEvent.click(openButton);

    // Panel should now be open
    await waitFor(() => {
      expect(screen.getByText('notes.admin.header_text')).toBeInTheDocument();
    });

    // Click close button
    const closeButton = screen.getByLabelText('notes.admin.aria_label.close_admin');
    userEvent.click(closeButton);

    // Panel should be closed, original button should be visible again
    await waitFor(() => {
      expect(screen.queryByText('notes.admin.header_text')).not.toBeInTheDocument();
      expect(screen.getByRole('button')).toBeInTheDocument();
    });
  });

  // Test note creation validation
  test('shows error when creating note with empty fields', async () => {
    renderWithProviders(<NotesPanel current_user={{ username: 'testuser' }}/>);

    // Open the admin notes panel
    const openButton = await screen.findByRole('button');
    userEvent.click(openButton);

    // Panel header should be visible
    await waitFor(() => {
      expect(screen.getByText('notes.admin.header_text')).toBeInTheDocument();
    });

    // Click to create a new note
    const createButton = screen.getByLabelText('notes.admin.aria_label.create_note');
    userEvent.click(createButton);

    await waitFor(() => {
      expect(screen.getByPlaceholderText('notes.note_title')).toBeInTheDocument();
      expect(screen.getByPlaceholderText('notes.note_text')).toBeInTheDocument();
    });

    // Select the postButton to create empty title and text
    const postButton = screen.getByLabelText('notes.admin.aria_label.post_created_note');

    // Submit the note
    fireEvent.click(postButton);

    await waitFor(() => {
      expect(sendNotification).toHaveBeenCalledWith(
        expect.any(Function),
        'Error',
        'notes.empty_fields'
      );
    });
  });

  // Test notes update/edit validation
  test('Error occurs when attempting to update or edit an existing note\'s text or title field with empty values', async () => {
    renderWithProviders(<NotesPanel current_user={{ username: 'testuser' }}/>);

    // Open the admin notes panel
    const openButton = await screen.findByRole('button');
    userEvent.click(openButton);

    // Panel header should be visible
    await waitFor(() => {
      expect(screen.getByText('notes.admin.header_text')).toBeInTheDocument();
      expect(screen.getByText('Bilbo baggins')).toBeInTheDocument();
    });

    // Select Edit button
    const editButton = screen.getByLabelText('notes.admin.aria_label.note_edit_button_focused');

    // Click editButton
    fireEvent.click(editButton);

    // Selects the input fields for the note title and note text
    const [noteTitleInput, noteTextInput] = screen.getAllByRole('textbox');

    // Clear Note title and text filed
    await userEvent.clear(noteTitleInput);
    await userEvent.clear(noteTextInput);

    // Select Save Button
    const saveButton = screen.getByLabelText('notes.admin.aria_label.note_edit_save_button_focused');

    // Save the edited note
    await fireEvent.click(saveButton);

    await waitFor(() => {
      expect(sendNotification).toHaveBeenCalledWith(
        expect.any(Function),
        'Error',
        'notes.empty_fields'
      );
    });
  });

  // Test note creation workflow
  test('can create a new note (CREATE)', async () => {
    renderWithProviders(<NotesPanel current_user={{ username: 'testuser' }} />);

    // Open the admin notes panel
    const openButton = await screen.findByRole('button');
    userEvent.click(openButton);

    // Panel header should be visible
    await waitFor(() => {
      expect(screen.getByText('notes.admin.header_text')).toBeInTheDocument();
    });

    // Click to create a new note
    const createButton = screen.getByLabelText('notes.admin.aria_label.create_note');
    userEvent.click(createButton);

    await waitFor(() => {
      expect(screen.getByPlaceholderText('notes.note_title')).toBeInTheDocument();
      expect(screen.getByPlaceholderText('notes.note_text')).toBeInTheDocument();
    });

    // Select the note fields
    const titleInput = screen.getByPlaceholderText('notes.note_title');
    const textInput = screen.getByPlaceholderText('notes.note_text');

    // Fill in the title and text field
    fireEvent.input(titleInput, { target: { value: 'New Test Title' } });
    fireEvent.input(textInput, { target: { value: 'New Test Text' } });

    // Make sure it's the correct title and text
    expect(titleInput).toHaveValue('New Test Title');
    expect(textInput).toHaveValue('New Test Text');

    // Select the postButton to create the newly entered title and text
    const postButton = screen.getByLabelText('notes.admin.aria_label.post_created_note');

    // Submit the note
    fireEvent.click(postButton);
  });

  // Test: Check/Read an existing note
  test('Check/Read an existing note (READ)', async () => {
    renderWithProviders(<NotesPanel current_user={{ username: 'testuser' }} />);

    // Open the admin notes panel
    const openButton = await screen.findByRole('button');
    userEvent.click(openButton);

    await waitFor(() => {
      expect(screen.getByLabelText('notes.admin.aria_label.expand_note')).toBeInTheDocument();
    });

    const textArea = screen.getByLabelText('notes.admin.aria_label.expand_note');

    fireEvent.click(textArea);

    await waitFor(() => {
      expect(screen.getByLabelText('notes.admin.aria_label.collapse_note')).toBeInTheDocument();
      expect(screen.getByLabelText('notes.admin.aria_label.note_details_focused')).toBeInTheDocument();
    });
  });

  test('Edit a existing note (UPDATE)', async () => {
    renderWithProviders(<NotesPanel current_user={{ username: 'testuser' }}/>);

    // Open the admin notes panel
    const openButton = await screen.findByRole('button');
    userEvent.click(openButton);

    // Panel header should be visible
    await waitFor(() => {
      expect(screen.getByText('notes.admin.header_text')).toBeInTheDocument();
      expect(screen.getByText('Bilbo baggins')).toBeInTheDocument();
    });

    // Select Edit button
    const editButton = screen.getByLabelText('notes.admin.aria_label.note_edit_button_focused');

    // Click editButton
    fireEvent.click(editButton);

    // Selects the input fields for the note title and note text
    const [noteTitleInput, noteTextInput] = screen.getAllByRole('textbox');

    // Simulates user typing a title related to "The Hobbit" into the note title input
    await userEvent.type(noteTitleInput, 'is the title character and protagonist of J. R. R. Tolkien\'s 1937 novel The Hobbit (source: Wikipedia)');

    // Simulates user typing a citation into the note text input
    await userEvent.type(noteTextInput, '(source: Wikipedia)');

    // Select Save Button
    const saveButton = screen.getByLabelText('notes.admin.aria_label.note_edit_save_button_focused');

    // Save the edited note
    await fireEvent.click(saveButton);

    await waitFor(() => {
      expect(screen.getByText('notes.edit_note')).toBeInTheDocument();
    });
  });

  test('Can delete a exiting note (DELETE)', async () => {
    renderWithProviders(
      <>
        <NotesPanel current_user={{ username: 'testuser' }} />
        <Confirm/>
      </>
    );

    // Open the admin notes panel
    const openButton = await screen.findByRole('button');
    userEvent.click(openButton);

    // Panel header should be visible
    await waitFor(() => {
      expect(screen.getByText('notes.admin.header_text')).toBeInTheDocument();
      expect(screen.getByText('Bilbo baggins')).toBeInTheDocument();
    });

    // Select and simulate the delete button
    const deleteButton = await screen.getByText('notes.delete_note');
    fireEvent.click(deleteButton);

    // Wait for the delete confirmation modal
    await waitFor(() => {
      expect(screen.getByText('application.confirm')).toBeInTheDocument();
    });

    // Select confirm  from the delete confirmation modal
    const confirmButton = screen.getByText('application.confirm');
    fireEvent.click(confirmButton);
  });
});
