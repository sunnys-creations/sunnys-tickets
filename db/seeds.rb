# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Emanuel', :city => cities.first)

if User.any?
  warn 'Database already has data, skipping seed.'
  return
end

# clear old caches to start from scratch
Rails.cache.clear
ApplicationModel.reset_column_information

# this is the __ordered__ list of seed files
# extend only if needed - try to add your changes
# to the matching one of the existing files
seeds = %w[settings user_nr_1 signatures roles permissions groups links ticket_state_types ticket_states ticket_priorities ticket_article_types ticket_article_senders macros community_user_resources overviews channels report_profiles chats object_manager_attributes schedulers triggers core_workflow]

# loop over and load all seedfiles
# files will get executed automatically
seeds.each do |seed|
  # we use load here to be able to re-seed in one process (test env)
  load Rails.root.join('db', 'seeds', "#{seed}.rb")
end

# set basic settings via environment variables
Setting.set('http_type', ENV['ZAMMAD_HTTP_TYPE']) if ENV['ZAMMAD_HTTP_TYPE']
Setting.set('fqdn',      ENV['ZAMMAD_FQDN'])      if ENV['ZAMMAD_FQDN']
Setting.set('storage_provider', 'S3')             if ENV['S3_URL'] && Rails.env.production?

# reset primary key sequences
DbHelper.import_post

# install locales and translations
Locale.create_if_not_exists(
  locale: 'en-us',
  alias:  'en',
  name:   __('English (United States)'),
)
Locale.sync
Translation.sync

Calendar.init_setup

# install all packages in auto_install
Package.auto_install
