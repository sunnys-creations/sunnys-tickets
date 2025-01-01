# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Common::ImportMode::Check < Sequencer::Unit::Base

  def process
    # check if system is in import mode
    return if Setting.get('import_mode')

    raise 'System is not in import mode!'
  end
end
