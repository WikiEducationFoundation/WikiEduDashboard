import React from 'react';
import { shallow } from 'enzyme';

import '../../testHelper';
import Block from '../../../app/assets/javascripts/components/timeline/block.jsx';

describe('Block', () => {
  const content = '<p>Welcome to Wikipedia</p>';
  const title = 'Welcome';
  const block = {
    id: 1,
    is_deletable: true,
    is_editable: true,
    content,
    title
  };
  it('should display the given block information and content', () => {
    const component = shallow(
      <Block block={block} trainingLibrarySlug="students" />
    );
    expect(component.find('.title').props().value).to.equal(title);
    expect(component.find('.block__block-content').props().value).to.equal(content);
  });
  it('should have an edit button if it is editable', () => {
    const component = shallow(
      <Block block={block} editPermissions={true} trainingLibrarySlug="students" />
    );
    expect(component.find('.block__edit-block').length).to.equal(1);
  });
  it('should not have an edit button if the user is not allowed', () => {
    const component = shallow(
      <Block block={block} editPermissions={false} trainingLibrarySlug="students" />
    );
    expect(component.find('.block__edit-block').length).to.equal(0);
  });
  it('should not have an edit button if the block cannot be edited', () => {
    const uneditableBlock = { ...block, is_editable: false };
    const component = shallow(
      <Block block={uneditableBlock} editPermissions={true} trainingLibrarySlug="students" />
    );
    expect(component.find('.block__edit-block').length).to.equal(0);
  });
  describe('editing block', () => {
    const props = {
      editableBlockIds: [block.id],
      saveBlockChanges: jest.fn(),
      cancelBlockEditable: jest.fn(),
      editPermissions: true,
      trainingLibrarySlug: 'students'
    };
    it('should show the edit fields', () => {
      const component = shallow(
        <Block block={block} {...props} />
      );
      expect(component.find('.title').props().editable).to.be.true;
    });
    it('should show the delete block button', () => {
      const component = shallow(
        <Block block={block} {...props} />
      );
      expect(component.find('.delete-block-container .danger').length).to.equal(1);
    });
    it('should not show the delete block button if the block is undeletable', () => {
      const undeletableBlock = { ...block, is_deletable: false };
      const component = shallow(
        <Block block={undeletableBlock} {...props} />
      );
      expect(component.find('.delete-block-container .danger').length).to.equal(0);
    });
  });
});
