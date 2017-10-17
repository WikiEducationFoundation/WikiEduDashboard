# frozen_string_literal: true

# Outputs coverage for any files that are not 100%
class SimplecovUncoveredFormatter
  def format(result)
    output = []
    result.groups.each_value do |files|
      files.each do |file|
        next if file.covered_percent == 100
        output << "#{file.filename} (coverage: #{file.covered_percent.round(2)}%)\n"
      end
    end
    # Only show this terminal output if there are no more than 20 files lacking
    # coverage. That way it won't annoy for partial spec runs.
    puts output unless output.count > 20
  end
end
