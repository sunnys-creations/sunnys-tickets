# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module ApplicationController::HasResponseExtentions
  extend ActiveSupport::Concern

  private

  def response_expand?
    return true if params[:expand] == true
    return true if params[:expand] == 'true'
    return true if params[:expand] == 1
    return true if params[:expand] == '1'

    false
  end

  def response_full?
    return true if params[:full] == true
    return true if params[:full] == 'true'
    return true if params[:full] == 1
    return true if params[:full] == '1'

    false
  end

  def response_all?
    return true if params[:all] == true
    return true if params[:all] == 'true'
    return true if params[:all] == 1
    return true if params[:all] == '1'

    false
  end

end
