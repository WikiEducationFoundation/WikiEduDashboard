# frozen_string_literal: true

class MergeInstitutions
  def initialize(survivor:, duplicate:)
    @survivor = survivor
    @duplicate = duplicate
  end

  def merge
    Institution.transaction do
      @duplicate.courses.update_all(institution_id: @survivor.id)
      @duplicate.reload.destroy!
    end
  end
end
