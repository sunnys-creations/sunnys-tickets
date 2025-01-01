# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

namespace :zammad do

  namespace :translations do

    desc 'Synchronize latest translations from i18n/*.po to the database.'
    task sync: :environment do
      puts 'Synchronizing the latest translations from i18n/*.po to the database...'
      Translation.sync
      puts 'done.'
    end
  end
end
