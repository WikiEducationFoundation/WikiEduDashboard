import React from 'react';
import PopoverButton from '../high_order/popover_button.jsx';
import TagStore from '../../stores/tag_store.coffee';

const tagIsNew = tag => TagStore.getFiltered({ tag }).length === 0;

const tags = (props, remove) =>
  props.tags.map(tag => {
    let removeButton = (
      <button className="button border plus" onClick={remove.bind(null, tag.id)}>-</button>
    );
    return (
      <tr key={`${tag.id}_tag`}>
        <td>{tag.tag}{removeButton}</td>
      </tr>
    );
  })
;

tags.propTypes = {
  tags: React.PropTypes.array
};

export default PopoverButton('tag', 'tag', TagStore, tagIsNew, tags);
