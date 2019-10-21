import React from 'react';
import { shallow } from 'enzyme';

import '../../../testHelper';
import { ModuleStatus } from '../../../../app/assets/javascripts/components/timeline/TrainingModules/ModuleStatus';

describe('ModuleStatus', () => {
  Features.enableAdvancedFeatures = true;
  const complete = jest.fn();
  const incomplete = jest.fn();
  const props = {
    block_id: 1,
    deadline_status: 'incomplete',
    due_date: 'DUEDATE',
    flags: {},
    kind: 1,
    module_progress: 'Incomplete',
    slug: 'course/slug',
    complete,
    incomplete
  };

  it('renders an incomplete exercise', () => {
    const Component = shallow(<ModuleStatus {...props} />);
    expect(Component.find('button')).toBeFalsey;
    expect(Component.text()).not.toContain('DUEDATE');
  });

  it('renders an exercise ready to be completed exercise', () => {
    const readied = {
      ...props,
      deadline_status: 'complete',
      module_progress: 'Complete'
    };
    const Component = shallow(<ModuleStatus {...readied} />);

    expect(Component.find('button')).toBeTruthy;
    expect(Component.find('button').text()).toEqual('Mark Complete');
    expect(Component.text()).not.toContain('DUEDATE');
  });

  it('fires the complete function', () => {
    const readied = {
      ...props,
      deadline_status: 'complete',
      module_progress: 'Complete'
    };
    const component = shallow(<ModuleStatus {...readied} />);
    component.find('button').props().onClick();

    expect(complete).toHaveBeenCalled();
  });

  it('renders an exercise that has been completed', () => {
    const readied = {
      ...props,
      deadline_status: 'complete',
      module_progress: 'Complete',
      flags: { marked_complete: true }
    };
    const Component = shallow(<ModuleStatus {...readied} />);

    expect(Component.find('button')).toBeTruthy;
    expect(Component.find('button').text()).toEqual('Mark Incomplete');
    expect(Component.text()).not.toContain('DUEDATE');
  });

  it('fires the complete function', () => {
    const readied = {
      ...props,
      deadline_status: 'complete',
      module_progress: 'Complete',
      flags: { marked_complete: true }
    };
    const component = shallow(<ModuleStatus {...readied} />);
    component.find('button').props().onClick();

    expect(incomplete).toHaveBeenCalled();
  });
});
