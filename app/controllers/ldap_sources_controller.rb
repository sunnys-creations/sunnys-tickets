# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class LdapSourcesController < ApplicationController
  include CanPrioritize

  prepend_before_action :authenticate_and_authorize!

  def index
    model_index_render(LdapSource, params)
  end

  def show
    model_show_render(LdapSource, params)
  end

  def create
    model_create_render(LdapSource, params)
  end

  def update
    model_update_render(LdapSource, params)
  end

  def destroy
    model_destroy_render(LdapSource, params)
  end
end
