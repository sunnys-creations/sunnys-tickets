# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Sequence::Import::Kayako::ConnectionTest < Sequencer::Sequence::Base
  def self.expecting
    [:connected]
  end

  def self.sequence
    [
      'Kayako::Connected',
    ]
  end
end
