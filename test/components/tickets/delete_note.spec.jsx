import React from 'react';
import configureMockStore from 'redux-mock-store';
import DeleteNote from '../../../app/assets/javascripts/components/tickets/delete_note.jsx';
import '../../testHelper';
import thunk from 'redux-thunk';
import { Provider } from 'react-redux';
import { mount } from 'enzyme';

const middlewares = [thunk];
const mockStore = configureMockStore(middlewares);
const store = mockStore({});

describe('Tickets', () => {
  describe('DeleteNote', () => {
    const props = {
      messageId: 53
    };

    const MockProvider = (mockProps) => {
      return (
        <Provider store={store}>
          <DeleteNote {...mockProps} />
        </Provider >
      );
    };
    const note = mount(<MockProvider {...props} />);

    it('should correctly render the component with Delete icon', () => {
      expect(note.find('img')).toBeTruthy();
    });
  });
});
