import SelectableBox from '../common/selectable_box';
import React from 'react';

const ScopingMethodTypes = () => {
  return (
    <div className="scoping-method-types">
      <SelectableBox
        description={I18n.t('courses_generic.creator.scoping_methods.categories_short_desc')}
        heading={I18n.t('courses_generic.creator.scoping_methods.categories')}
        style={{ width: '90%', margin: 0 }}
      />
      <SelectableBox
        description={I18n.t('courses_generic.creator.scoping_methods.templates_short_desc')}
        heading={I18n.t('courses_generic.creator.scoping_methods.templates')}
        style={{ width: '90%', margin: 0 }}
      />
      <SelectableBox
        description={I18n.t('courses_generic.creator.scoping_methods.petscan_short_desc')}
        heading={I18n.t('courses_generic.creator.scoping_methods.petscan')}
        style={{ width: '90%', margin: 0 }}
      />
      <SelectableBox
        description={I18n.t('courses_generic.creator.scoping_methods.pagepile_short_desc')}
        heading={I18n.t('courses_generic.creator.scoping_methods.pagepile')}
        style={{ width: '90%', margin: 0 }}
      />
    </div>
  );
};

export default ScopingMethodTypes;
