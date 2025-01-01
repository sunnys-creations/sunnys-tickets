# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require_dependency 'tasks/zammad/command.rb'

module Tasks
  module Zammad
    module DB
      class Pgloader < Tasks::Zammad::Command

        def self.description
          'Prints out pgloader command file for the data migration from MySQL/MariaDB to PostgreSQL server.'
        end

        def self.task_handler
          raise "Incorrect database configuration, expected `mysql2` for adapter but got `#{config['adapter']}`, check your database.yml!" if config['adapter'] != 'mysql2'

          puts command_file
        end

        def self.command_file
          <<~PGLOADER
            LOAD DATABASE
              FROM #{mysql_url}

              -- Adjust the PostgreSQL URL below to correct value before executing this command file.
              INTO pgsql://zammad:pgsql_password@localhost/zammad

            ALTER SCHEMA '#{config['database']}' RENAME TO 'public'

            AFTER LOAD DO
            #{smime_certificates.concat(pgp_keys).concat(public_links).concat(object_manager_attributes).join(",\n")}

            WITH BATCH CONCURRENCY = 1
            SET timezone = 'UTC'
            SET client_timezone TO '00:00'
            ;
          PGLOADER
        end

        # Generate URL of the source MySQL server:
        #   mysql://[mysql_username[:mysql_password]@][mysql_host[:mysql_port]/][mysql_database]
        def self.mysql_url
          url = 'mysql://'

          url += url_credentials(config['username'], config['password'])
          url += url_hostname(config.fetch('host', 'localhost'), config['port'])
          url += url_path(config['database'])

          url
        end

        def self.config
          return JSON.parse(ENV['ZAMMAD_TEST_DATABASE_CONFIG']) if ENV['ZAMMAD_TEST_DATABASE_CONFIG'].present?

          Rails.configuration.database_configuration[Rails.env]
        end

        def self.url_credentials(username, password)
          credentials = ''

          if username.present?
            credentials += username

            if password.present?
              credentials += ":#{password}"
            end

            credentials += '@'
          end

          credentials
        end

        def self.url_hostname(host, port)
          hostname = ''

          if host.present?
            hostname += host

            if port.present?
              hostname += ":#{port}"
            end

            hostname += '/'
          end

          hostname
        end

        def self.url_path(database)
          path = ''

          if database.present?
            path += database
          end

          path
        end

        # Use character varying type for the array columns, so it matches the initial type used on PSQL backends.
        #   https://github.com/zammad/zammad/issues/5409
        def self.alter_table_command(table, column)
          "  $$ alter table #{table} alter column #{column} type varchar[] using translate(#{column}::varchar, '[]', '{}')::varchar[] $$"
        end

        def self.object_manager_attributes
          ObjectManager::Attribute.where(data_type: %w[multiselect multi_tree_select]).map do |field|
            alter_table_command(field.object_lookup.name.constantize.table_name, field.name)
          end
        end

        def self.pgp_keys
          [alter_table_command(PGPKey.table_name, 'email_addresses')]
        end

        def self.public_links
          [alter_table_command(PublicLink.table_name, 'screen')]
        end

        def self.smime_certificates
          [alter_table_command(SMIMECertificate.table_name, 'email_addresses')]
        end

        private_class_method :config, :url_credentials, :url_hostname, :url_path, :alter_table_command, :object_manager_attributes, :public_links, :pgp_keys, :smime_certificates
      end
    end
  end
end
