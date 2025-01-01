# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Authorization < ApplicationModel
  belongs_to    :user, optional: true
  after_create  :delete_user_cache, :notification_send
  after_update  :delete_user_cache
  after_destroy :delete_user_cache
  validates     :user_id,  presence: true
  validates     :uid,      presence: true, uniqueness: { case_sensitive: true, scope: :provider }
  validates     :provider, presence: true

  def self.find_from_hash(hash)
    auth = Authorization.find_by(provider: hash['provider'], uid: hash['uid'])
    if auth

      # update auth tokens
      auth.update!(
        token:  hash['credentials']['token'],
        secret: hash['credentials']['secret']
      )

      # update username of auth entry if empty
      if !auth.username && hash['info']['nickname'].present?
        auth.update!(
          username: hash['info']['nickname'],
        )
      end

      # update firstname/lastname if needed
      user = User.find(auth.user_id)
      if user.firstname.blank? && user.lastname.blank?
        if hash['info']['first_name'].present? && hash['info']['last_name'].present?
          user.firstname = hash['info']['first_name']
          user.lastname = hash['info']['last_name']
        elsif hash['info']['display_name'].present?
          user.firstname = hash['info']['display_name']
        end
      end

      # update image if needed
      if hash['info']['image'].present?
        avatar = Avatar.add(
          object:        'User',
          o_id:          user.id,
          url:           hash['info']['image'],
          source:        hash['provider'],
          deletable:     true,
          updated_by_id: user.id,
          created_by_id: user.id,
        )
        if avatar && user.image != avatar.store_hash
          user.image = avatar.store_hash
        end
      end

      if user.changed?
        user.save
      end
    end
    auth
  end

  def self.create_from_hash(hash, user = nil)

    auth_provider = "#{PROVIDER_CLASS_PREFIX}#{hash['provider'].camelize}".constantize.new(hash, user)

    # save/update avatar
    if hash['info'].present? && hash['info']['image'].present?
      avatar = Avatar.add(
        object:        'User',
        o_id:          auth_provider.user.id,
        url:           hash['info']['image'],
        source:        auth_provider.name,
        deletable:     true,
        updated_by_id: auth_provider.user.id,
        created_by_id: auth_provider.user.id,
      )

      # update user link
      if avatar && auth_provider.user.image != avatar.store_hash
        auth_provider.user.image = avatar.store_hash
        auth_provider.user.save
      end
    end

    Authorization.create!(
      user:     auth_provider.user,
      uid:      auth_provider.uid,
      username: hash['info']['nickname'] || hash['info']['username'] || hash['info']['name'] || hash['info']['email'] || hash['username'],
      provider: auth_provider.name,
      token:    hash['credentials']['token'],
      secret:   hash['credentials']['secret']
    )
  end

  private

  PROVIDER_CLASS_PREFIX = 'Authorization::Provider::'.freeze

  def delete_user_cache
    return if !user

    user.touch # rubocop:disable Rails/SkipsModelValidations
  end

  # An account is considered linked if the user originates from a source other than the current authorization provider.
  def linked_account?
    user.source != provider
  end

  def notification_send

    # Send a notification only if the feature is turned on and the account is linked.
    return if !Setting.get('auth_third_party_linking_notification') || !user || !linked_account?

    template = 'user_auth_provider'

    if user.email.blank?
      Rails.logger.info { "Unable to send a notification (#{template}) to user_id: #{user.id} be cause of missing email address." }
      return
    end

    Rails.logger.debug { "Send notification (#{template}) to: #{user.email}" }

    NotificationFactory::Mailer.notification(
      template: template,
      user:     user,
      objects:  {
        user:     user,
        provider: provider_name(provider),
      }
    )
  end

  def provider_name(provider)
    return saml_display_name(provider) if provider == 'saml'

    provider_title(provider)
  end

  # In case of SAML authentication provider, there is a separate display name setting that may be defined.
  def saml_display_name(provider)
    begin
      Setting.get('auth_saml_credentials')['display_name']
    rescue
      provider_title(provider)
    end
  end

  def provider_title(provider)
    begin
      Setting.find_by(name: "auth_#{provider}").preferences['title_i18n'].shift
    rescue
      provider
    end
  end

end
