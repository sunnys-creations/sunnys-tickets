# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::TimeEntries < Sequencer::Unit::Import::Kayako::SubSequence::Object
  def sequence_name
    'Sequencer::Sequence::Import::Kayako::TimeEntries'.freeze
  end
end
