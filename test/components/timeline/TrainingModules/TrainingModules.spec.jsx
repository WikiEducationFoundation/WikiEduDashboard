import React from 'react';
import { mount } from 'enzyme';
import { Provider } from 'react-redux';
import configureMockStore from 'redux-mock-store';

import '~/test/testHelper';
import TrainingModules from '@components/timeline/TrainingModules/TrainingModules';

describe('TrainingModules', () => {
  const fakeModules = [
    {
      id: 1,
      block_id: 11,
      name: 'Module Name 1',
      value: 'test1',
      label: 'test1',
      flags: {},
      due_date: '2019/01/01',
      module_progress: 'progress',
      slug: 'training-slug-1'
    },
    {
      id: 2,
      block_id: 12,
      name: 'Module Name 2',
      value: 'test2',
      label: 'test2',
      flags: {},
      due_date: '2019/01/01',
      module_progress: 'progress',
      slug: 'training-slug-2'
    },
    {
      id: 3,
      block_id: 13,
      name: 'Module Name 3',
      value: 'test3',
      label: 'test3',
      flags: {},
      due_date: '2019/01/01',
      module_progress: 'progress',
      slug: 'training-slug-3'
    }
  ];
  const store = configureMockStore()({
    course: { id: 99 }
  });

  describe('render training module types (machine tests)', () => {
    const TrainingModulesM = mount(
      <Provider store={store}>
        <TrainingModules
          block_modules={fakeModules}
          all_modules={['module1', 'module2', 'module3']}
          trainingLibrarySlug="students"
        />
      </Provider>
    );

    describe('Initial State', () => {
      it('should map array block_modules with their ids', () => {
        const state = TrainingModulesM.find('TrainingModules').instance().getInitialState();
        expect(state).toBeInstanceOf(Object);
        expect(state).toHaveProperty('value');
      });
    });
    describe('onChange', () => {
      it('should map trainingModule to TrainingModules.value', () => {
        const onChange = sinon.stub(TrainingModulesM.find('TrainingModules').instance(), 'onChange').callsFake(() => true);
        expect(onChange.returnValues).toBeInstanceOf(Array);
      });
    });
    describe('trainingSelector', () => {
      it('should return object', () => {
        expect(TrainingModulesM.find('TrainingModules').instance().trainingSelector()).toBeInstanceOf(Object);
      });
    });
  });
  describe('render (human-like tests)', () => {
    describe('tests without edit-mode', () => {
      const test1 = {
        block_id: 115,
        flags: {},
        deadline_status: 'complete',
        due_date: '2017/12/09',
        kind: 0,
        id: 15,
        module_progress: 'Complete',
        name: 'Let it test',
        overdue: false,
        slug: 'let-it-test'
      };

      const TrainingModulesH = mount(
        <Provider store={store}>
          <TrainingModules
            block_modules={[test1]}
            editable={false}
            header="Training"
            trainingLibrarySlug="students"
          />
        </Provider>
      );
      describe('components testing', () => {
        it('`h4` text', () => {
          expect(TrainingModulesH.find('h4').text()).toEqual('Training');
        });
        describe('testing classes of components', () => {
          expect(TrainingModulesH.find('div.block__training-modules')).toHaveLength(1);
          expect(TrainingModulesH.find('table.table.table--small')).toHaveLength(1);
          expect(TrainingModulesH.find('tr.training-module')).toHaveLength(1);
          expect(TrainingModulesH.find('td.block__training-modules-table__module-name')).toHaveLength(1);
          expect(TrainingModulesH.find('tr.training-module')).toHaveLength(1);
          expect(TrainingModulesH.find('td.block__training-modules-table__module-link')).toHaveLength(1);
          describe('status testing', () => {
            describe('progress', () => {
              it('Complete', () => {
                expect(TrainingModulesH.find('td.timeline-module__progress-complete.block__training-modules-table__module-progress')).toHaveLength(1);
                expect(TrainingModulesH.find('a.Complete')).toHaveLength(1);
                expect(TrainingModulesH.find('a.Complete').text()).toEqual('View');
              });
              it('in-progress', () => {
                const testTemp = {
                  block_id: 115,
                  flags: {},
                  deadline_status: 'complete',
                  due_date: '2017/12/09',
                  id: 15,
                  kind: 0,
                  module_progress: 'in-progress',
                  name: 'Let it test',
                  overdue: false,
                  slug: 'let-it-test'
                };
                const TrainingModulesTEMP = mount(<Provider store={store}><TrainingModules block_modules={[testTemp]} editable={false} trainingLibrarySlug="students" /></Provider>);
                expect(TrainingModulesTEMP.find('td.timeline-module__in-progress.block__training-modules-table__module-progress')).toHaveLength(1);
                expect(TrainingModulesTEMP.find('a.in-progress')).toHaveLength(1);
                expect(TrainingModulesTEMP.find('a.in-progress').text()).toEqual('Continue');
              });
              it('overdue (Complete)', () => {
                const testTemp = {
                  block_id: 115,
                  flags: {},
                  deadline_status: 'complete',
                  due_date: '2017/12/09',
                  id: 15,
                  kind: 0,
                  module_progress: 'Complete',
                  name: 'Let it test',
                  overdue: true,
                  slug: 'let-it-test'
                };
                const TrainingModulesTEMP = mount(<Provider store={store}><TrainingModules block_modules={[testTemp]} editable={false} trainingLibrarySlug="students" /></Provider>);
                expect(TrainingModulesTEMP.find('td.timeline-module__progress-complete.overdue')).toHaveLength(1);
              });
              it('overdue (in-progress)', () => {
                const testTemp = {
                  block_id: 115,
                  flags: {},
                  deadline_status: 'complete',
                  due_date: '2017/12/09',
                  id: 15,
                  kind: 0,
                  module_progress: 'in-progress',
                  name: 'Let it test',
                  overdue: true,
                  slug: 'let-it-test'
                };
                const TrainingModulesTEMP = mount(<Provider store={store}><TrainingModules block_modules={[testTemp]} editable={false} trainingLibrarySlug="students" /></Provider>);
                expect(TrainingModulesTEMP.find('td.timeline-module__in-progress.overdue')).toHaveLength(1);
              });
              describe('deadline_status', () => {
                describe('complete', () => {
                  it('without overdue', () => {
                    const testTemp = {
                      block_id: 115,
                      flags: {},
                      deadline_status: 'complete',
                      due_date: '2017/12/09',
                      id: 15,
                      kind: 0,
                      module_progress: 'Complete',
                      name: 'Let it test',
                      overdue: false,
                      slug: 'let-it-test'
                    };
                    const TrainingModulesTEMP = mount(<Provider store={store}><TrainingModules block_modules={[testTemp]} editable={false} trainingLibrarySlug="students" /></Provider>);
                    expect(TrainingModulesTEMP.find('td.timeline-module__progress-complete.complete')).toHaveLength(1);
                  });
                  it('with overdue', () => {
                    const testTemp = {
                      block_id: 115,
                      flags: {},
                      deadline_status: 'complete',
                      due_date: '2017/12/09',
                      id: 15,
                      kind: 0,
                      module_progress: 'Complete',
                      name: 'Let it test',
                      overdue: true,
                      slug: 'let-it-test'
                    };
                    const TrainingModulesTEMP = mount(<Provider store={store}><TrainingModules block_modules={[testTemp]} editable={false} trainingLibrarySlug="students" /></Provider>);
                    expect(TrainingModulesTEMP.find('td.timeline-module__progress-complete.overdue.complete')).toHaveLength(1);
                  });
                });
                describe('in-progress', () => {
                  it('without overdue', () => {
                    const testTemp = {
                      block_id: 115,
                      flags: {},
                      deadline_status: 'complete',
                      due_date: '2017/12/09',
                      id: 15,
                      kind: 0,
                      module_progress: 'in-progress',
                      name: 'Let it test',
                      overdue: false,
                      slug: 'let-it-test'
                    };
                    const TrainingModulesTEMP = mount(<Provider store={store}><TrainingModules block_modules={[testTemp]} editable={false} trainingLibrarySlug="students" /></Provider>);
                    expect(TrainingModulesTEMP.find('td.timeline-module__in-progress.complete')).toHaveLength(1);
                  });
                  it('with overdue', () => {
                    const testTemp = {
                      block_id: 115,
                      flags: {},
                      deadline_status: 'complete',
                      due_date: '2017/12/09',
                      id: 15,
                      kind: 0,
                      module_progress: 'in-progress',
                      name: 'Let it test',
                      overdue: true,
                      slug: 'let-it-test'
                    };
                    const TrainingModulesTEMP = mount(<Provider store={store}><TrainingModules block_modules={[testTemp]} editable={false} trainingLibrarySlug="students" /></Provider>);
                    expect(TrainingModulesTEMP.find('td.timeline-module__in-progress.overdue.complete')).toHaveLength(1);
                  });
                });
              });
            });
            describe('deadline_status', () => {
               it('overdue', () => {
                 const testTemp = {
                   block_id: 115,
                   flags: {},
                   deadline_status: 'overdue',
                   due_date: '2017/12/09',
                   id: 15,
                   kind: 0,
                   module_progress: 'in-progress',
                   name: 'Let it test',
                   overdue: true,
                   slug: 'let-it-test'
                 };
                 const TrainingModulesTEMP = mount(<Provider store={store}><TrainingModules block_modules={[testTemp]} editable={false} trainingLibrarySlug="students" /></Provider>);
                 expect(TrainingModulesTEMP.find('td.overdue').text()).toMatch(/due on 2017\/12\/09/i);
               });
            });
          });
        });
      });
    });
    describe('tests with edit-mode', () => {
      const test1 = {
        deadline_status: 'complete',
        due_date: '2017/12/09',
        id: 15,
        kind: 0,
        module_progress: 'Complete',
        name: 'Let it test',
        overdue: false,
        slug: 'let-it-test',
        value: 'test1',
        label: 'test1'
      };
      const test2 = {
        deadline_status: 'complete',
        due_date: '2017/12/09',
        id: 16,
        kind: 0,
        module_progress: 'Complete',
        name: 'Let it change',
        overdue: false,
        slug: 'let-it-change',
        value: 'test2',
        label: 'test2'
      };
      const onChangeSpy = sinon.spy();
      const TrainingModulesEM = mount(<TrainingModules block_modules={[test1]} editable={true} all_modules={[test1, test2]} onChange={onChangeSpy} trainingLibrarySlug="students" />);
      it('onChange', () => {
        TrainingModulesEM.find('Select').instance().props.onChange([test1, test2]);
        expect(onChangeSpy.called).toBeTruthy;
      });
    });
  });

  describe('render other module types', () => {
    describe('Initial State', () => {
      const exercise = {
        block_id: 115,
        flags: {},
        deadline_status: 'complete',
        due_date: '2017/12/09',
        kind: 1,
        id: 15,
        module_progress: 'Complete',
        name: 'Exercise',
        overdue: false,
        slug: 'exercise'
      };

      const Modules = mount(
        <Provider store={store}>
          <TrainingModules
            block_modules={[exercise]}
            editable={false}
            header="Exercises"
            trainingLibrarySlug="students"
          />
        </Provider>
      );

      it('should map array block_modules with their ids', () => {
        const state = Modules.find('TrainingModules').instance().getInitialState();
        expect(state).toBeInstanceOf(Object);
        expect(state).toHaveProperty('value');
        expect(state.value).toBeInstanceOf(Array);
        expect(state.value.length).toEqual(1);
      });
      it('should display trainings with the appropriate text', () => {
        const container = Modules.find('TrainingModules');
        const tr = container.find('tr');
        expect(tr.length).toEqual(1);
        expect(tr.find('ModuleStatus'));
        expect(tr.text()).toContain('Exercise');
        expect(tr.text()).toContain('View');
      });
    });

    describe('Initial State', () => {
      const discussion = {
        block_id: 115,
        flags: {},
        deadline_status: 'complete',
        due_date: '2017/12/09',
        kind: 2,
        id: 15,
        module_progress: 'Complete',
        name: 'Discussion',
        overdue: false,
        slug: 'discussion'
      };

      const Modules = mount(
        <Provider store={store}>
          <TrainingModules
            block_modules={[discussion]}
            editable={false}
            header="Discussions"
            trainingLibrarySlug="students"
          />
        </Provider>
      );

      it('should map array block_modules with their ids', () => {
        const state = Modules.find('TrainingModules').instance().getInitialState();
        expect(state).toBeInstanceOf(Object);
        expect(state).toHaveProperty('value');
        expect(state.value).toBeInstanceOf(Array);
        expect(state.value.length).toEqual(1);
      });
      it('should display trainings with the appropriate text', () => {
        const container = Modules.find('TrainingModules');
        const tr = container.find('tr');
        expect(tr.length).toEqual(1);
        expect(tr.find('ModuleStatus'));
        expect(tr.text()).toContain('Discussion');
        expect(tr.text()).toContain('View');
      });
    });
  });
});
