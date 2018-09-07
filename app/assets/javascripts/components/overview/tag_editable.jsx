import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import Select from 'react-select';


import { getAvailableTags } from '../../selectors';

import PopoverExpandable from '../high_order/popover_expandable.jsx';
import Popover from '../common/popover.jsx';
import Conditional from '../high_order/conditional.jsx';

import { removeTag, fetchAllTags, addTag } from '../../actions/tag_actions';


const TagEditable = createReactClass({
  displayName: 'TagEditable',

  getInitialState() {
    return { createdTagOption: [] };
  },

  componentDidMount() {
    return this.props.fetchAllTags();
  },

  getKey() {
    return 'add_tag';
  },

  PropTypes: {
    tags: PropTypes.array.isRequired,
    availableTags: PropTypes.array.isRequired,
    fetchAllTags: PropTypes.func.isRequired,
    addTag: PropTypes.func.isRequired
  },

  handleChangeTag(val) {
    if (val) {
      const { value, className } = val;
      // The value includes a className of Select-create-option-placeholder if it's a user-created option.
      // In that case, we need to add it to the list of options, so that it shows up as selected.
      if (className) {
        this.setState({ createdTagOption: [{ value, label: value }] });
      }
      this.setState({ selectedTag: value });
    } else {
      this.setState({ selectedTag: null });
    }
  },

  openPopover(e) {
    if (!this.props.is_open) {
      this.refs.tagSelect.focus();
    }
    return this.props.open(e);
  },

  removeTag(tagId) {
    this.props.removeTag(this.props.course_id, tagId);
  },

  addTag() {
    this.props.addTag(this.props.course_id, this.state.selectedTag);
    this.setState({ selectedTag: null });
  },

  render() {
    // In editable mode we'll show a list of tags and a remove button plus a selector to add new tags
    const tagList = this.props.tags.map(tag => {
      const removeButton = (
        <button className="button border plus" onClick={this.removeTag.bind(this, tag.tag)}>-</button>
      );
      return (
        <tr key={`${tag.id}_tag`}>
          <td>{tag.tag}{removeButton}</td>
        </tr>
      );
    });

    let tagSelect;
    if (this.props.availableTags.length > 0) {
      const availableOptions = this.props.availableTags.map(tag => {
        return { label: tag, value: tag };
      });
      const tagOptions = [...this.state.createdTagOption, ...availableOptions];
      let addTagButtonDisabled = true;
      if (this.state.selectedTag) {
        addTagButtonDisabled = false;
      }
      tagSelect = (
        <tr>
          <th>
            <div className="select-with-button">
              <Select.Creatable
                className="fixed-width"
                ref="tagSelect"
                name="tag"
                value={this.state.selectedTag}
                placeholder={I18n.t('courses.tag_select')}
                onChange={this.handleChangeTag}
                options={tagOptions}
              />
              <button type="submit" className="button dark" disabled={addTagButtonDisabled} onClick={this.addTag}>
                Add
              </button>
            </div>
          </th>
        </tr>
      );
    }

    return (
      <div key="tags" className="pop__container tags open" onClick={this.stop}>
        <button className="button border plus open" onClick={this.openPopover}>+</button>
        <Popover
          is_open={this.props.is_open}
          edit_row={tagSelect}
          rows={tagList}
        />
      </div>
    );
  }

});

const mapStateToProps = state => ({
  availableTags: getAvailableTags(state),
  tags: state.tags.tags
});

const mapDispatchToProps = {
  removeTag,
  addTag,
  fetchAllTags
};

export default connect(mapStateToProps, mapDispatchToProps)(
  Conditional(PopoverExpandable(TagEditable))
);
