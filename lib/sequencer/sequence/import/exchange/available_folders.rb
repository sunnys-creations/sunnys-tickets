# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Sequence::Import::Exchange::AvailableFolders < Sequencer::Sequence::Base

  def self.expecting
    [:folders]
  end

  def self.sequence
    [
      'Exchange::Connection',
      'Exchange::Folders::IdPathMap',
      'Import::Exchange::AttributeMapper::AvailableFolders',
    ]
  end
end
