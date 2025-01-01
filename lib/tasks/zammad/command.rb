# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'English'

module Tasks
  module Zammad

    # Base class for CLI commands in Zammad.
    # Rake is not intended for a real CLI style usage, that is why we need
    #   to apply some workarounds here.
    class Command

      # Infer the rake task name from the class name.
      def self.task_name
        name.underscore.sub('tasks/', '').tr('/', ':').to_sym
      end

      # Override this if the task needs additional arguments.
      # Currently only a fixed number of arguments is supported.
      ARGUMENT_COUNT = 0

      def self.usage
        "Usage: bundle exec rails #{task_name}"
      end

      # Needs to be implemented by child classes.
      def self.description
        raise "The required method 'description' is not implemented by #{name}"
      end

      # Needs to be implemented by child classes.
      def self.task_handler
        raise "The required method 'task_handler' is not implemented by #{name}"
      end

      def self.register_rake_task
        Rake::Task.define_task task_name => :environment do
          run_task
        end.add_description(description)
      end

      def self.run_task
        validate_comandline
        task_handler
      rescue => e
        # A bit more user friendly than plain Rake.
        Rails.logger.error e
        abort "Error: #{e.message}"
      end

      # Prevent the execution of multiple commands at once (mostly because of codebase
      #  self-modification in 'zammad:package:install').
      # Enforce the correct number of expected arguments.
      def self.validate_comandline
        args = ArgvHelper.argv
        if args.first.to_sym != task_name || args.count != (const_get(:ARGUMENT_COUNT) + 1)
          abort "Error: wrong number of arguments given.\n#{usage}"
        end
        # Rake will try to run additional arguments as tasks, so make sure nothing happens for these.
        args[1..].each { |a| Rake::Task.define_task(a.to_sym => :environment) {} } # rubocop:disable Lint/EmptyBlock
      end

      # Rake switches the current working directory to the Rails root.
      # Make sure that relative pathnames still get resolved correctly.
      # Note: This works only when invoked via 'rake', not 'rails'!
      def self.resolve_filepath(path)
        given_path = Pathname.new(path)

        return given_path if given_path.absolute?

        Pathname.new(Rake.original_dir).join(path)
      end

      def self.exec_command(cmd)
        puts "> #{cmd}"
        puts `#{cmd}`
        puts ''
        raise if !$CHILD_STATUS.success?
      end
    end
  end
end
