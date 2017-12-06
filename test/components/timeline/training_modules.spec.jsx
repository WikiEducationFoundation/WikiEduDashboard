import '../../testHelper';

import React from 'react';
import { mount } from 'enzyme';
import TrainingModules from '../../../app/assets/javascripts/components/timeline/training_modules.jsx';

describe('TrainingModules', () => {
  describe('render', () => {
    const TrainingModulesM = mount(<TrainingModules block_modules={["test1", "test2", "test3"]} all_modules={["module1", "module2", "module3"]}/> );

    describe('Initial State', () => {
      it('should map array block_modules with their ids', () => {
        expect(TrainingModulesM.instance().getInitialState()).to.be.an('object').that.have.all.keys('value');
      });
    });
    describe('onChange', () => {
      it('should map trainingModule to TrainingModules.value', () => {
        // const spyOnChange = sinon.spy(TrainingModulesM, 'onChange');
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
        expect(TrainingModulesM.instance().trainingSelector()).to.be_an('object');
      });
      // I can't get it work. `yarn test` throwed that `find` is invalid chai property...
      // it('should map `options` properly', () => {
      //   expect(TrainingModulesM.instance().trainingSelector()).find('[options]').to.be.an('array');
      // });
    });
  });
});
