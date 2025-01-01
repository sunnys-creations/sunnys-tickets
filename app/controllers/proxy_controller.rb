# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class ProxyController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  # POST /api/v1/proxy
  def test
    url = 'http://zammad.org'
    options = params
      .permit(:proxy, :proxy_username, :proxy_password, :proxy_no)
      .to_h
    options[:open_timeout] = 12
    options[:read_timeout] = 24
    begin
      result = UserAgent.get(
        url,
        {},
        options,
      )
    rescue => e
      render json: {
        result:  'failed',
        message: e.inspect
      }
      return
    end
    if result.success?
      render json: {
        result: 'success'
      }
      return
    end
    render json: {
      result:  'failed',
      message: result.body || result.error || result.code
    }
  end

end
