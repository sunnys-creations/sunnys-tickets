# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class VersionController < ApplicationController

  prepend_before_action :authenticate_and_authorize!

  # GET /api/v1/version
  def index
    render json: {
      version: Version.get
    }
  end

end
