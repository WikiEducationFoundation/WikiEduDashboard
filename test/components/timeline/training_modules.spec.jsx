import '../../testHelper';

import React from 'react';
import { mount } from 'enzyme';
import TrainingModules from '../../../app/assets/javascripts/components/timeline/training_modules.jsx';

describe('TrainingModules', () => {
  describe('render (machine tests)', () => {
    const TrainingModulesM = mount(<TrainingModules block_modules={["test1", "test2", "test3"]} all_modules={["module1", "module2", "module3"]} />);

    describe('Initial State', () => {
      it('should map array block_modules with their ids', () => {
        expect(TrainingModulesM.instance().getInitialState()).to.be.an('object').that.have.all.keys('value');
      });
    });
    describe('onChange', () => {
      it('should map trainingModule to TrainingModules.value', () => {
        const onChange = sinon.stub(TrainingModulesM.instance(), 'onChange').callsFake(() => true);
        expect(onChange.returnValues).to.be.an('array');
      });
    });
    describe('progressClass', () => {
      it('should return progress complete when \'Complete\' is given', () => {
        expect(TrainingModulesM.instance().progressClass('Complete')).to.be.an('String').and.to.equal('timeline-module__progress-complete ');
      });
      it('should return in-progress when nothing is given', () => {
        expect(TrainingModulesM.instance().progressClass()).to.be.an('String').and.to.equal('timeline-module__in-progress ');
      });
    });
    describe('trainingSelector', () => {
      it('should return object', () => {
        expect(TrainingModulesM.instance().trainingSelector()).to.be.an('object');
      });
    });
  });
  describe('render (human-like tests)', () => {
    describe('tests without edit-mode', () => {
      const test1 = {
        deadline_status: "complete",
        due_date: "2017/12/09",
        id: 15,
        module_progress: "Complete",
        name: "Let it test",
        overdue: false,
        slug: "let-it-test"
      };

      const TrainingModulesH = mount(<TrainingModules block_modules={[test1]} editable={false} />);
      describe('components testing', () => {
        it('`h4` text', () => {
          expect(TrainingModulesH.find('h4').text()).to.eq('Training');
        });
        describe('testing classes of components', () => {
          expect(TrainingModulesH.find('div.block__training-modules')).to.have.length(1);
          expect(TrainingModulesH.find('table.table.table--small')).to.have.length(1);
          expect(TrainingModulesH.find('tr.training-module')).to.have.length(1);
          expect(TrainingModulesH.find('td.block__training-modules-table__module-name')).to.have.length(1);
          expect(TrainingModulesH.find('tr.training-module')).to.have.length(1);
          expect(TrainingModulesH.find('td.block__training-modules-table__module-link')).to.have.length(1);
          describe('status testing', () => {
            describe('progress', () => {
              it('Complete', () => {
                expect(TrainingModulesH.find('td.timeline-module__progress-complete.block__training-modules-table__module-progress')).to.have.length(1);
                expect(TrainingModulesH.find('a.Complete')).to.have.length(1);
                expect(TrainingModulesH.find('a.Complete').text()).to.equal('View');
              });
              it('in-progress', () => {
                const testTemp = {
                  deadline_status: "complete",
                  due_date: "2017/12/09",
                  id: 15,
                  module_progress: "in-progress",
                  name: "Let it test",
                  overdue: false,
                  slug: "let-it-test"
                };
                const TrainingModulesTEMP = mount(<TrainingModules block_modules={[testTemp]} editable={false} />);
                expect(TrainingModulesTEMP.find('td.timeline-module__in-progress.block__training-modules-table__module-progress')).to.have.length(1);
                expect(TrainingModulesTEMP.find('a.in-progress')).to.have.length(1);
                expect(TrainingModulesTEMP.find('a.in-progress').text()).to.equal('Continue');
              });
              it('overdue (Complete)', () => {
                const testTemp = {
                  deadline_status: "complete",
                  due_date: "2017/12/09",
                  id: 15,
                  module_progress: "Complete",
                  name: "Let it test",
                  overdue: true,
                  slug: "let-it-test"
                };
                const TrainingModulesTEMP = mount(<TrainingModules block_modules={[testTemp]} editable={false} />);
                expect(TrainingModulesTEMP.find('td.timeline-module__progress-complete.overdue')).to.have.length(1);
              });
              it('overdue (in-progress)', () => {
                const testTemp = {
                  deadline_status: "complete",
                  due_date: "2017/12/09",
                  id: 15,
                  module_progress: "in-progress",
                  name: "Let it test",
                  overdue: true,
                  slug: "let-it-test"
                };
                const TrainingModulesTEMP = mount(<TrainingModules block_modules={[testTemp]} editable={false} />);
                expect(TrainingModulesTEMP.find('td.timeline-module__in-progress.overdue')).to.have.length(1);
              });
              describe('deadline_status', () => {
                describe('complete', () => {
                  it('without overdue', () => {
                    const testTemp = {
                      deadline_status: "complete",
                      due_date: "2017/12/09",
                      id: 15,
                      module_progress: "Complete",
                      name: "Let it test",
                      overdue: false,
                      slug: "let-it-test"
                    };
                    const TrainingModulesTEMP = mount(<TrainingModules block_modules={[testTemp]} editable={false} />);
                    expect(TrainingModulesTEMP.find('td.timeline-module__progress-complete.complete')).to.have.length(1);
                  });
                  it('with overdue', () => {
                    const testTemp = {
                      deadline_status: "complete",
                      due_date: "2017/12/09",
                      id: 15,
                      module_progress: "Complete",
                      name: "Let it test",
                      overdue: true,
                      slug: "let-it-test"
                    };
                    const TrainingModulesTEMP = mount(<TrainingModules block_modules={[testTemp]} editable={false} />);
                    expect(TrainingModulesTEMP.find('td.timeline-module__progress-complete.overdue.complete')).to.have.length(1);
                  });
                });
                describe('in-progress', () => {
                  it('without overdue', () => {
                    const testTemp = {
                      deadline_status: "complete",
                      due_date: "2017/12/09",
                      id: 15,
                      module_progress: "in-progress",
                      name: "Let it test",
                      overdue: false,
                      slug: "let-it-test"
                    };
                    const TrainingModulesTEMP = mount(<TrainingModules block_modules={[testTemp]} editable={false} />);
                    expect(TrainingModulesTEMP.find('td.timeline-module__in-progress.complete')).to.have.length(1);
                  });
                  it('with overdue', () => {
                    const testTemp = {
                      deadline_status: "complete",
                      due_date: "2017/12/09",
                      id: 15,
                      module_progress: "in-progress",
                      name: "Let it test",
                      overdue: true,
                      slug: "let-it-test"
                    };
                    const TrainingModulesTEMP = mount(<TrainingModules block_modules={[testTemp]} editable={false} />);
                    expect(TrainingModulesTEMP.find('td.timeline-module__in-progress.overdue.complete')).to.have.length(1);
                  });
                });
              });
            });
            describe('deadline_status', () => {
               it('overdue', () => {
                 const testTemp = {
                   deadline_status: "overdue",
                   due_date: "2017/12/09",
                   id: 15,
                   module_progress: "in-progress",
                   name: "Let it test",
                   overdue: true,
                   slug: "let-it-test"
                 };
                 const TrainingModulesTEMP = mount(<TrainingModules block_modules={[testTemp]} editable={false} />);
                 expect(TrainingModulesTEMP.find('td.overdue').text()).to.match(/due on 2017\/12\/09/i);
               });
            });
          });
        });
      });
    });
    describe('tests with edit-mode', () => {
      const test1 = {
        deadline_status: "complete",
        due_date: "2017/12/09",
        id: 15,
        module_progress: "Complete",
        name: "Let it test",
        overdue: false,
        slug: "let-it-test"
      };
      const test2 = {
        deadline_status: "complete",
        due_date: "2017/12/09",
        id: 16,
        module_progress: "Complete",
        name: "Let it change",
        overdue: false,
        slug: "let-it-change"
      };
      const onChangeSpy = sinon.spy();
      const TrainingModulesEM = mount(<TrainingModules block_modules={[test1]} editable={true} all_modules={[test1, test2]} onChange={onChangeSpy} />);
      it('onChange', () => {
        TrainingModulesEM.find('Select').instance().props.onChange([test1, test2]);
        expect(onChangeSpy.called).to.be.true;
      });
    });
  });
});
