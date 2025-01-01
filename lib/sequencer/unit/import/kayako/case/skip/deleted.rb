# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::Case::Skip::Deleted < Sequencer::Unit::Base

  uses :resource
  provides :action

  def process
    return if resource['state'] != 'TRASH'

    logger.info { "Skipping. Kayako Case ID '#{resource['id']}' is in 'TRASH' state." }
    state.provide(:action, :skipped)
  end
end
