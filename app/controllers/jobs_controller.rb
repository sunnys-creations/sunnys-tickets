# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class JobsController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  def index
    model_index_render(Job, params)
  end

  def show
    model_show_render(Job, params)
  end

  def create
    model_create_render(Job, params)
  end

  def update
    model_update_render(Job, params)
  end

  def destroy
    model_destroy_render(Job, params)
  end

end
