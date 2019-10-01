import React from 'react';
import { mount } from 'enzyme';

import '../../testHelper';
import TrainingModules from '../../../app/assets/javascripts/components/timeline/training_modules.jsx';

describe('TrainingModules', () => {
  const fakeModules = [{ id: 1, value: 'test1', label: 'test1' }, { id: 2, value: 'test2', label: 'test2' }, { id: 3, value: 'test3', label: 'test3' }];
  describe('render (machine tests)', () => {
    const TrainingModulesM = mount(<TrainingModules block_modules={fakeModules} all_modules={['module1', 'module2', 'module3']} trainingLibrarySlug="students" />);

    describe('Initial State', () => {
      it('should map array block_modules with their ids', () => {
        const state = TrainingModulesM.instance().getInitialState()
        expect(state).toBeInstanceOf(Object);
        expect(state).toHaveProperty('value');
      });
    });
    describe('onChange', () => {
      it('should map trainingModule to TrainingModules.value', () => {
        const onChange = sinon.stub(TrainingModulesM.instance(), 'onChange').callsFake(() => true);
        expect(onChange.returnValues).toBeInstanceOf(Array);
      });
    });
    describe('progressClass', () => {
      it('should return progress complete when \'Complete\' is given', () => {
        const complete = TrainingModulesM.instance().progressClass('Complete');
        expect(typeof complete).toEqual('string');
        expect(complete).toEqual('timeline-module__progress-complete ');
      });
      it('should return in-progress when nothing is given', () => {
        const actual = TrainingModulesM.instance().progressClass();
        expect(typeof actual).toEqual('string');
        expect(actual).toEqual('timeline-module__in-progress ');
      });
    });
    describe('trainingSelector', () => {
      it('should return object', () => {
        expect(TrainingModulesM.instance().trainingSelector()).toBeInstanceOf(Object);
      });
    });
  });
  describe('render (human-like tests)', () => {
    describe('tests without edit-mode', () => {
      const test1 = {
        deadline_status: 'complete',
        due_date: '2017/12/09',
        id: 15,
        module_progress: 'Complete',
        name: 'Let it test',
        overdue: false,
        slug: 'let-it-test'
      };

      const TrainingModulesH = mount(<TrainingModules block_modules={[test1]} editable={false} trainingLibrarySlug="students" />);
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
                  deadline_status: 'complete',
                  due_date: '2017/12/09',
                  id: 15,
                  module_progress: 'in-progress',
                  name: 'Let it test',
                  overdue: false,
                  slug: 'let-it-test'
                };
                const TrainingModulesTEMP = mount(<TrainingModules block_modules={[testTemp]} editable={false} trainingLibrarySlug="students" />);
                expect(TrainingModulesTEMP.find('td.timeline-module__in-progress.block__training-modules-table__module-progress')).toHaveLength(1);
                expect(TrainingModulesTEMP.find('a.in-progress')).toHaveLength(1);
                expect(TrainingModulesTEMP.find('a.in-progress').text()).toEqual('Continue');
              });
              it('overdue (Complete)', () => {
                const testTemp = {
                  deadline_status: 'complete',
                  due_date: '2017/12/09',
                  id: 15,
                  module_progress: 'Complete',
                  name: 'Let it test',
                  overdue: true,
                  slug: 'let-it-test'
                };
                const TrainingModulesTEMP = mount(<TrainingModules block_modules={[testTemp]} editable={false} trainingLibrarySlug="students" />);
                expect(TrainingModulesTEMP.find('td.timeline-module__progress-complete.overdue')).toHaveLength(1);
              });
              it('overdue (in-progress)', () => {
                const testTemp = {
                  deadline_status: 'complete',
                  due_date: '2017/12/09',
                  id: 15,
                  module_progress: 'in-progress',
                  name: 'Let it test',
                  overdue: true,
                  slug: 'let-it-test'
                };
                const TrainingModulesTEMP = mount(<TrainingModules block_modules={[testTemp]} editable={false} trainingLibrarySlug="students" />);
                expect(TrainingModulesTEMP.find('td.timeline-module__in-progress.overdue')).toHaveLength(1);
              });
              describe('deadline_status', () => {
                describe('complete', () => {
                  it('without overdue', () => {
                    const testTemp = {
                      deadline_status: 'complete',
                      due_date: '2017/12/09',
                      id: 15,
                      module_progress: 'Complete',
                      name: 'Let it test',
                      overdue: false,
                      slug: 'let-it-test'
                    };
                    const TrainingModulesTEMP = mount(<TrainingModules block_modules={[testTemp]} editable={false} trainingLibrarySlug="students" />);
                    expect(TrainingModulesTEMP.find('td.timeline-module__progress-complete.complete')).toHaveLength(1);
                  });
                  it('with overdue', () => {
                    const testTemp = {
                      deadline_status: 'complete',
                      due_date: '2017/12/09',
                      id: 15,
                      module_progress: 'Complete',
                      name: 'Let it test',
                      overdue: true,
                      slug: 'let-it-test'
                    };
                    const TrainingModulesTEMP = mount(<TrainingModules block_modules={[testTemp]} editable={false} trainingLibrarySlug="students" />);
                    expect(TrainingModulesTEMP.find('td.timeline-module__progress-complete.overdue.complete')).toHaveLength(1);
                  });
                });
                describe('in-progress', () => {
                  it('without overdue', () => {
                    const testTemp = {
                      deadline_status: 'complete',
                      due_date: '2017/12/09',
                      id: 15,
                      module_progress: 'in-progress',
                      name: 'Let it test',
                      overdue: false,
                      slug: 'let-it-test'
                    };
                    const TrainingModulesTEMP = mount(<TrainingModules block_modules={[testTemp]} editable={false} trainingLibrarySlug="students" />);
                    expect(TrainingModulesTEMP.find('td.timeline-module__in-progress.complete')).toHaveLength(1);
                  });
                  it('with overdue', () => {
                    const testTemp = {
                      deadline_status: 'complete',
                      due_date: '2017/12/09',
                      id: 15,
                      module_progress: 'in-progress',
                      name: 'Let it test',
                      overdue: true,
                      slug: 'let-it-test'
                    };
                    const TrainingModulesTEMP = mount(<TrainingModules block_modules={[testTemp]} editable={false} trainingLibrarySlug="students" />);
                    expect(TrainingModulesTEMP.find('td.timeline-module__in-progress.overdue.complete')).toHaveLength(1);
                  });
                });
              });
            });
            describe('deadline_status', () => {
               it('overdue', () => {
                 const testTemp = {
                   deadline_status: 'overdue',
                   due_date: '2017/12/09',
                   id: 15,
                   module_progress: 'in-progress',
                   name: 'Let it test',
                   overdue: true,
                   slug: 'let-it-test'
                 };
                 const TrainingModulesTEMP = mount(<TrainingModules block_modules={[testTemp]} editable={false} trainingLibrarySlug="students" />);
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
});
