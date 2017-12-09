class UpdateLog
  ####################
  # CONSTANTS        #
  ####################
  MAX_UPDATES_TO_KEEP = 10

  def self.log_updates(starttime, endtime)
    add_new_log(starttime, endtime)
    delete_old_log
    log_delay
    save_setting
  end

  def self.average_delay
    setting_record
    @setting.value['average_delay'] ? @setting.value['average_delay']: nil
  end

  def self.last_update
    setting_record
    @setting.value['constant_update'] ? @setting.value['constant_update'].values.last['end_time'] : nil
  end

  class << self

    def setting_record
      @setting = Setting.find_or_create_by(key: 'metrics_update')
    end
    
    def add_new_log(starttime, endtime)
      setting_record
      if @setting.value['constant_update'] === nil
        @setting.value['constant_update'] = Hash.new
      end
      @last_update = @setting.value['constant_update'].keys.last
      if @last_update === nil
        index = 0 
      else
        index = @last_update + 1
      end
      @setting.value['constant_update'][index] = {'start_time' => starttime, 'end_time' => endtime}
    end

    def delete_old_log
      return @setting.value['constant_update'].delete(@last_update - MAX_UPDATES_TO_KEEP) if @last_update != nil && @last_update >= MAX_UPDATES_TO_KEEP
    end

    def log_delay
      constant_update = @setting.value['constant_update']
      return unless constant_update
      seconds = constant_update.keys.length > 1 ? constant_update.map {|key, value| (Time.parse(constant_update[key]["end_time"].to_s) - Time.parse(constant_update[key-1]["end_time"].to_s) if key != constant_update.keys[0]).to_i} : [0]
      @setting.value['average_delay'] = seconds.inject(:+)/(seconds.length-1) if seconds.length > 1
    end

    def save_setting
      @setting.save
    end
  end

end