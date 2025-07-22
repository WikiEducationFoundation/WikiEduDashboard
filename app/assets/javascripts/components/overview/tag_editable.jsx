import React, { useEffect, useRef, useState } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import CreatableSelect from 'react-select/creatable';

import { getAvailableTags } from '../../selectors';
import selectStyles from '../../styles/select';

import Popover from '../common/popover.jsx';
import Conditional from '../high_order/conditional.jsx';

import { removeTag, fetchAllTags, addTag } from '../../actions/tag_actions';
import useExpandablePopover from '../../hooks/useExpandablePopover';


const TagEditable = ({ course_id }) => {
  const availableTags = useSelector(state => getAvailableTags(state));
  const tags = useSelector(state => state.tags.tags);
  const dispatch = useDispatch();

  const [createdTagOption, setCreatedTagOption] = useState([]);
  const [selectedTag, setSelectedTag] = useState();
  const tagSelectRef = useRef(null);

  useEffect(() => { dispatch(fetchAllTags()); }, []);

  const getKey = () => {
    return 'add_tag';
  };

  const { isOpen, ref, open } = useExpandablePopover(getKey);

  const handleChangeTag = (val) => {
    if (!val) {
      setSelectedTag(null);
      return;
    }

    // The value includes `__isNew__: true` if it's a user-created option.
    // In that case, we need to add it to the list of options, so that it shows up as selected.
    const isNew = val.__isNew__;
    if (isNew) {
      setCreatedTagOption([val]);
    }
    setSelectedTag(val);
  };

  const openPopover = (e) => {
    if (!isOpen) {
      tagSelectRef.current.focus();
    }
    return open(e);
  };

  const removeTagHandler = (tagId) => {
    dispatch(removeTag(course_id, tagId));
  };

  const addTagHandler = () => {
    dispatch(addTag(course_id, selectedTag.value));
    setSelectedTag(null);
  };

  // In editable mode we'll show a list of tags and a remove button plus a selector to add new tags
  const tagList = tags.map((tag) => {
    const removeButton = (
      <button className="button border plus" aria-label="Remove tag" onClick={() => removeTagHandler(tag.tag)}>-</button>
    );
    return (
      <tr key={`${tag.id}_tag`}>
        <td>{tag.tag}{removeButton}</td>
      </tr>
    );
  });

  const availableOptions = availableTags.map((tag) => {
    return { label: tag, value: tag };
  });
  const tagOptions = [...createdTagOption, ...availableOptions];
  let addTagButtonDisabled = true;
  if (selectedTag) {
    addTagButtonDisabled = false;
  }
  const tagSelect = (
    <tr>
      <th>
        <div className="select-with-button">
          <CreatableSelect
            className="fixed-width"
            ref={tagSelectRef}
            name="tag"
            value={selectedTag}
            placeholder={I18n.t('courses.tag_select')}
            onChange={handleChangeTag}
            options={tagOptions}
            styles={selectStyles}
            isClearable
          />
          <button type="submit" className="button dark" disabled={addTagButtonDisabled} onClick={addTagHandler}>
            Add
          </button>
        </div>
      </th>
    </tr>
  );

  return (
    <div key="tags" className="pop__container tags open" ref={ref}>
      <button
        className="button border plus open" onClick={openPopover}
        aria-label={I18n.t('courses.new_tag_button_aria_label')}
      >+
      </button>
      <Popover
        is_open={isOpen}
        edit_row={tagSelect}
        rows={tagList}
      />
    </div>
  );
};

export default (Conditional(TagEditable));
