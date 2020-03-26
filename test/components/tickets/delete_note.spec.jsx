import React from 'react';
import { shallow } from 'enzyme';
import configureMockStore from 'redux-mock-store';
import DeleteNote from '../../../app/assets/javascripts/components/tickets/delete_note.jsx';
import '../../testHelper';

const mockStore = configureMockStore();
const store = mockStore({});
describe('Tickets', () => {
      describe('DeleteNote', () => {
             const props = {
                  messageId: 53
             };
             const note = shallow(<DeleteNote store={store} {...props} />);
             it('should correctly render the component with Delete icon', () => {
                   expect(note.find('img')).toBeTruthy();
             });
      });
});
