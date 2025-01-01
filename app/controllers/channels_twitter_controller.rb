# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class ChannelsTwitterController < ApplicationController
  prepend_before_action :authenticate_and_authorize!, except: %i[webhook_incoming webhook_verify]
  skip_before_action :verify_csrf_token, only: %i[webhook_incoming webhook_verify]

  before_action :validate_webhook_signature!, only: :webhook_incoming

  def webhook_incoming
    @channel.process(params.permit!.to_h)
    render json: {}
  end

  def validate_webhook_signature!
    header_name     = 'x-twitter-webhooks-signature'
    given_signature = request.headers[header_name]
    raise Exceptions::UnprocessableEntity, "Missing '#{header_name}' header" if given_signature.blank?

    calculated_signature = hmac_signature_by_app(request.raw_post)
    raise Exceptions::NotAuthorized if calculated_signature != given_signature
    raise Exceptions::UnprocessableEntity, __("The required parameter 'for_user_id' is missing.") if params[:for_user_id].blank?

    @channel = nil
    Channel.where(area: 'Twitter::Account', active: true).each do |channel|
      next if channel.options[:user].blank?
      next if channel.options[:user][:id].to_s != params[:for_user_id].to_s

      @channel = channel
    end

    raise Exceptions::UnprocessableEntity, "Could not find channel for user id '#{params[:for_user_id]}'!" if !@channel

    true
  end

  def hmac_signature_by_app(content)
    external_credential = ExternalCredential.find_by(name: 'twitter')
    raise Exceptions::UnprocessableEntity, __("The required 'ExternalCredential' 'twitter' could not be found.") if !external_credential

    hmac_signature_gen(external_credential.credentials[:consumer_secret], content)
  end

  def hmac_signature_gen(consumer_secret, content)
    hashed = OpenSSL::HMAC.digest('sha256', consumer_secret, content)
    hashed = Base64.strict_encode64(hashed)
    "sha256=#{hashed}"
  end

  def webhook_verify
    external_credential = Rails.cache.read('external_credential_twitter')
    if !external_credential && ExternalCredential.exists?(name: 'twitter')
      external_credential = ExternalCredential.find_by(name: 'twitter').credentials
    end
    raise Exceptions::UnprocessableEntity, __('The required value external_credential could not be found in the cache.') if external_credential.blank?
    raise Exceptions::UnprocessableEntity, __("The required value 'external_credential[:consumer_secret]' could not be found in the cache.") if external_credential[:consumer_secret].blank?
    raise Exceptions::UnprocessableEntity, __("The required parameter 'crc_token' is missing from the Twitter verify payload!") if params['crc_token'].blank?

    render json: {
      response_token: hmac_signature_gen(external_credential[:consumer_secret], params['crc_token'])
    }
  end

  def index
    assets = {}
    external_credential_ids = []
    ExternalCredential.where(name: 'twitter').each do |external_credential|
      assets = external_credential.assets(assets)
      external_credential_ids.push external_credential.id
    end
    channel_ids = []
    Channel.where(area: 'Twitter::Account').reorder(:id).each do |channel|
      assets = channel.assets(assets)
      channel_ids.push channel.id
    end
    render json: {
      assets:                  assets,
      channel_ids:             channel_ids,
      external_credential_ids: external_credential_ids,
      callback_url:            ExternalCredential.callback_url('twitter'),
    }
  end

  def update
    model_update_render(Channel, params)
  end

  def enable
    channel = Channel.find_by(id: params[:id], area: 'Twitter::Account')
    channel.active = true
    channel.save!
    render json: {}
  end

  def disable
    channel = Channel.find_by(id: params[:id], area: 'Twitter::Account')
    channel.active = false
    channel.save!
    render json: {}
  end

  def destroy
    channel = Channel.find_by(id: params[:id], area: 'Twitter::Account')
    channel.destroy
    render json: {}
  end

end
