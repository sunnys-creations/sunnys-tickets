# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Sequence::Import::Kayako::UserField < Sequencer::Sequence::Base

  def self.sequence
    [
      'Common::ModelClass::User',
      'Import::Kayako::ObjectAttribute::Skip',
      'Import::Kayako::ObjectAttribute::SanitizedName',
      'Import::Kayako::ObjectAttribute::Config',
      'Import::Kayako::ObjectAttribute::Add',
      'Import::Kayako::ObjectAttribute::MigrationExecute',
      'Import::Kayako::ObjectAttribute::FieldMap',
    ]
  end
end
