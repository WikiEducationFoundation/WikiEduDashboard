import React from 'react';
import { mount } from 'enzyme';

import '~/test/testHelper';
import { ModuleStatus } from '@components/timeline/TrainingModules/ModuleRow/ModuleStatus/ModuleStatus';

describe('ModuleStatus', () => {
  Features.enableAdvancedFeatures = true;
  const complete = jest.fn(() => Promise.resolve());
  const incomplete = jest.fn(() => Promise.resolve());
  const fetchExercises = jest.fn();
  const props = {
    block_id: 1,
    course: { id: 10 },
    deadline_status: 'incomplete',
    due_date: 'DUEDATE',
    flags: {},
    kind: 1,
    module_progress: 'Incomplete',
    progressClass: 'in-progress',
    slug: 'course/slug',
    complete,
    incomplete,
    fetchExercises
  };

  it('renders an incomplete exercise', () => {
    const Component = mount(
      <table>
        <tbody>
          <tr>
            <ModuleStatus {...props} />
          </tr>
        </tbody>
      </table>
    );
    expect(Component.find('button')).toBeTruthy;
    expect(Component.find('button').text()).toEqual('Mark Complete');
    expect(Component.find('button').props().disabled).toBeTruthy;
    expect(Component.text()).not.toContain('DUEDATE');
  });

  it('renders an exercise ready to be completed exercise', () => {
    const readied = {
      ...props,
      deadline_status: 'complete',
      module_progress: 'Complete'
    };
    const Component = mount(
      <table>
        <tbody>
          <tr>
            <ModuleStatus {...readied} />
          </tr>
        </tbody>
      </table>
    );
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
    const component = mount(
      <table>
        <tbody>
          <tr>
            <ModuleStatus {...readied} />
          </tr>
        </tbody>
      </table>
    );
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
    const Component = mount(
      <table>
        <tbody>
          <tr>
            <ModuleStatus {...readied} />
          </tr>
        </tbody>
      </table>
    );
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
    const component = mount(
      <table>
        <tbody>
          <tr>
            <ModuleStatus {...readied} />
          </tr>
        </tbody>
      </table>
    );
    component.find('button').props().onClick();

    expect(incomplete).toHaveBeenCalled();
  });
});
