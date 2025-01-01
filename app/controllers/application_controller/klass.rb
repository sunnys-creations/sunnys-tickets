# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module ApplicationController::Klass
  extend ActiveSupport::Concern

  included do
    def klass
      @klass ||= controller_path.classify.constantize
    end
  end
end
