import React, { useState, useEffect } from "react";
import PropTypes from "prop-types";
import Select, { components } from "react-select";
import { filter, compact } from "lodash-es";
import selectStyles from "../../../styles/select";
import ModuleRow from "./ModuleRow/ModuleRow";
import { EXERCISE_KIND, DISCUSSION_KIND } from "../../../constants";

const TrainingModules = ({
  allModules, // Array of all training modules (required)
  blockModules, // Array of training modules for this block (required)
  editable, // Boolean indicating editability (required)
  header, // String for the header title (optional)
  isStudent, // Boolean indicating student view (required)
  onChange, // Function to handle changes (required)
  trainingLibrarySlug, // String for training library slug (required)
}) => {
  // State for selected training modules
  const [value, setValue] = useState([]);

  // Update selected modules on blockModules change
  useEffect(() => {
    if (blockModules) {
      const selections = blockModules.map((module) => ({
        value: module.id,
        label: module.name + moduleLabel(module.kind),
      }));
      setValue(selections);
    }
  }, [blockModules]); // Dependency array for useEffect

  const handleChange = (selections) => {
    const trainingModuleIds =
      selections?.map((trainingModule) => trainingModule.value) || [];
    setValue(selections);
    onChange(trainingModuleIds);
  };

  const moduleLabel = (kind) => {
    if (kind === EXERCISE_KIND) {
      return ` (${I18n.t("training.kind.exercise")})`;
    }
    if (kind === DISCUSSION_KIND) {
      return ` (${I18n.t("training.kind.discussion")})`;
    }
    return ` (${I18n.t("training.kind.training")})`;
  };

  const trainingSelector = () => {
    const MultiValueRemove = (props) => (
      <components.MultiValueRemove {...props}>
        <components.CrossIcon aria-hidden={false} aria-label="Remove Module" />
      </components.MultiValueRemove>
    );

    const options = filter(
      compact(allModules),
      (module) => module.status !== "deprecated"
    ).map((module) => ({
      value: module.id,
      label: module.name + moduleLabel(module.kind),
    }));

    return (
      <div className="block__training-modules">
        <div>
          <h4>Training modules</h4>
          <Select
            components={{ MultiValueRemove }}
            isMulti
            name="block-training-modules"
            value={value}
            options={options}
            onChange={handleChange}
            placeholder="Add training module(s)..."
            styles={selectStyles}
            aria-label="Training modules"
          />
        </div>
      </div>
    );
  };

  return (
    <>
      {/* Render training selector if editable */}
      {editable && trainingSelector()}

      {/* Render training modules list if not editable */}
      {!editable &&
        blockModules?.length > 0 && ( // Check for blockModules length
          <div className="block__training-modules">
            <div>
              {header ? (
                <h4
                  id={header
                    .toLowerCase()
                    .split(/[^a-z]/)
                    .join("-")}
                >
                  {header}
                </h4>
              ) : null}
              <table className="table table--small">
                <tbody>
                  {blockModules.map((module) => (
                    <ModuleRow
                      key={module.id}
                      isStudent={isStudent}
                      module={module}
                      trainingLibrarySlug={trainingLibrarySlug}
                    />
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}
    </>
  );
};

TrainingModules.propTypes = {
  allModules: PropTypes.array.isRequired,
  blockModules: PropTypes.array.isRequired,
  editable: PropTypes.bool.isRequired,
  header: PropTypes.any,
  isStudent: PropTypes.bool.isRequired,
  onChange: PropTypes.func.isRequired,
  trainingLibrarySlug: PropTypes.string.isRequired,
};

export default TrainingModules;
