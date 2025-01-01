# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class EmailHelper
  class Probe

    #
    # Try to guess email channel configuration from basic user data.
    #
    def self.full(params)

      user, domain = EmailHelper.parse_email(params[:email])

      if !user || !domain
        return {
          result:   'invalid',
          messages: {
            email: "Invalid email '#{params[:email]}'."
          },
        }
      end

      # probe provider based settings
      provider_map = EmailHelper.provider(params[:email], params[:password])
      domains = [domain]

      # get mx records, try to find provider based on mx records
      mx_records = EmailHelper.mx_records(domain)
      domains.concat(mx_records)
      provider_map.each_value do |settings|
        domains.each do |domain_to_check|

          next if !domain_to_check.match?(%r{#{settings[:domain]}}i)

          # add folder to config if needed
          if params[:folder].present? && settings[:inbound] && settings[:inbound][:options]
            settings[:inbound][:options][:folder] = params[:folder]
          end

          config_set_verify_ssl(settings[:inbound], params)
          config_set_verify_ssl(settings[:outbound], params)

          # probe inbound
          Rails.logger.debug { "INBOUND PROBE PROVIDER: #{settings[:inbound].inspect}" }
          result_inbound = EmailHelper::Probe.inbound(settings[:inbound])
          Rails.logger.debug { "INBOUND RESULT PROVIDER: #{result_inbound.inspect}" }
          next if result_inbound[:result] != 'ok'

          # probe outbound
          Rails.logger.debug { "OUTBOUND PROBE PROVIDER: #{settings[:outbound].inspect}" }
          result_outbound = EmailHelper::Probe.outbound(settings[:outbound], params[:email])
          Rails.logger.debug { "OUTBOUND RESULT PROVIDER: #{result_outbound.inspect}" }
          next if result_outbound[:result] != 'ok'

          return {
            result:                       'ok',
            content_messages:             result_inbound[:content_messages],
            archive_possible:             result_inbound[:archive_possible],
            archive_possible_is_fallback: result_inbound[:archive_possible_is_fallback],
            archive_week_range:           result_inbound[:archive_week_range],
            setting:                      settings,
          }
        end
      end

      # probe guess settings

      # probe inbound
      inbound_mx = EmailHelper.provider_inbound_mx(user, params[:email], params[:password], mx_records)
      inbound_guess = EmailHelper.provider_inbound_guess(user, params[:email], params[:password], domain)
      inbound_map = inbound_mx + inbound_guess
      result = {
        result:  'ok',
        setting: {}
      }
      success = false
      inbound_map.each do |config|

        # add folder to config if needed
        if params[:folder].present? && config[:options]
          config[:options][:folder] = params[:folder]
        end

        # Add SSL verification flag to configuration, if needed.
        config_set_verify_ssl(config, params)

        Rails.logger.debug { "INBOUND PROBE GUESS: #{config.inspect}" }
        result_inbound = EmailHelper::Probe.inbound(config)
        Rails.logger.debug { "INBOUND RESULT GUESS: #{result_inbound.inspect}" }

        next if result_inbound[:result] != 'ok'

        success                     = true
        result[:setting][:inbound]  = config
        result[:content_messages]   = result_inbound[:content_messages]
        result[:archive_possible]   = result_inbound[:archive_possible]
        result[:archive_possible_is_fallback] = result_inbound[:archive_possible_is_fallback]
        result[:archive_week_range] = result_inbound[:archive_week_range]

        break
      end

      # give up, no possible inbound found
      if !success
        return {
          result: 'failed',
          reason: 'inbound failed',
        }
      end

      # probe outbound
      outbound_mx = EmailHelper.provider_outbound_mx(user, params[:email], params[:password], mx_records)
      outbound_guess = EmailHelper.provider_outbound_guess(user, params[:email], params[:password], domain)
      outbound_map = outbound_mx + outbound_guess

      success = false
      outbound_map.each do |config|

        # Add SSL verification flag to configuration, if needed.
        config_set_verify_ssl(config, params)

        Rails.logger.debug { "OUTBOUND PROBE GUESS: #{config.inspect}" }
        result_outbound = EmailHelper::Probe.outbound(config, params[:email])
        Rails.logger.debug { "OUTBOUND RESULT GUESS: #{result_outbound.inspect}" }

        next if result_outbound[:result] != 'ok'

        success                     = true
        result[:setting][:outbound] = config
        break
      end

      # give up, no possible outbound found
      if !success
        return {
          result: 'failed',
          reason: 'outbound failed',
        }
      end
      Rails.logger.debug { "PROBE FULL SUCCESS: #{result.inspect}" }
      result
    end

    #
    # Validate an inbound email channel configuration.
    #
    def self.inbound(params)

      adapter = params[:adapter].downcase

      # validate adapter
      if !EmailHelper.available_driver[:inbound][adapter.to_sym]
        return {
          result:  'failed',
          message: "Unknown adapter '#{adapter}'",
        }
      end

      # connection test
      result_inbound = {}
      begin
        driver_class    = "Channel::Driver::#{adapter.to_classname}".constantize
        driver_instance = driver_class.new
        result_inbound  = driver_instance.fetch(params[:options], nil, 'check')
      rescue => e
        Rails.logger.debug { e }

        return {
          result:        'invalid',
          settings:      params,
          message:       e.message,
          message_human: translation(e.message),
          invalid_field: invalid_field(e.message),
        }
      end
      result_inbound
    end

    #
    # Validate an outbound email channel configuration.
    #
    def self.outbound(params, email, subject = nil)

      adapter = params[:adapter].downcase

      # validate adapter
      if !EmailHelper.available_driver[:outbound][adapter.to_sym]
        return {
          result:  'failed',
          message: "Unknown adapter '#{adapter}'",
        }
      end

      # prepare test email
      # rubocop:disable Zammad/DetectTranslatableString
      mail = if subject
               {
                 from:    email,
                 to:      email,
                 subject: "Zammad Getting started Test Email #{subject}",
                 body:    "This is a test email from Zammad to check if email sending and receiving work correctly.\n\nYou can ignore or delete this email.",
               }
             else
               {
                 from:    email,
                 to:      'verify-external-smtp-sending@discard.zammad.org',
                 subject: 'This is a Test Email',
                 body:    "This is a test email from Zammad to verify if Zammad can send emails to an external address.\n\nIf you see this email, you can ignore or delete it.",
               }
             end
      # rubocop:enable Zammad/DetectTranslatableString

      if subject.present?
        mail['X-Zammad-Test-Message'] = subject
      end
      mail['X-Zammad-Ignore']          = 'true'
      mail['X-Zammad-Fqdn']            = Setting.get('fqdn')
      mail['X-Zammad-Verify']          = 'true'
      mail['X-Zammad-Verify-Time']     = Time.zone.now.iso8601
      mail['X-Loop']                   = 'yes'
      mail['Precedence']               = 'bulk'
      mail['Auto-Submitted']           = 'auto-generated'
      mail['X-Auto-Response-Suppress'] = 'All'

      # test connection
      begin
        driver_class    = "Channel::Driver::#{adapter.to_classname}".constantize
        driver_instance = driver_class.new
        driver_instance.deliver(
          params[:options],
          mail,
        )
      rescue => e
        Rails.logger.debug { e }

        # check if sending email was ok, but mailserver rejected
        if !subject
          white_map = {
            'Recipient address rejected'                => true,
            'Sender address rejected: Domain not found' => true,
          }
          white_map.each_key do |key|

            next if !e.message.match?(%r{#{Regexp.escape(key)}}i)

            return {
              result:   'ok',
              settings: params,
              notice:   e.message,
            }
          end
        end

        return {
          result:        'invalid',
          settings:      params,
          message:       e.message,
          message_human: translation(e.message),
          invalid_field: invalid_field(e.message),
        }
      end
      {
        result: 'ok',
      }
    end

    def self.invalid_field(message_backend)
      invalid_fields.each do |key, fields|
        return fields if message_backend.match?(%r{#{Regexp.escape(key)}}i)
      end
      {}
    end

    def self.invalid_fields
      {
        'authentication failed'                                     => { user: true, password: true },
        'Username and Password not accepted'                        => { user: true, password: true },
        'Incorrect username'                                        => { user: true, password: true },
        'Lookup failed'                                             => { user: true },
        'Invalid credentials'                                       => { user: true, password: true },
        'getaddrinfo: nodename nor servname provided, or not known' => { host: true },
        'getaddrinfo: Name or service not known'                    => { host: true },
        'No route to host'                                          => { host: true },
        'execution expired'                                         => { host: true },
        'Connection refused'                                        => { host: true },
        'Mailbox doesn\'t exist'                                    => { folder: true },
        'Folder doesn\'t exist'                                     => { folder: true },
        'Unknown Mailbox'                                           => { folder: true },
      }
    end

    def self.translation(message_backend)
      translations.each do |key, message_human|
        return message_human if message_backend.match?(%r{#{Regexp.escape(key)}}i)
      end
      nil
    end

    def self.translations
      {
        'authentication failed'                                     => __('Authentication failed.'),
        'Username and Password not accepted'                        => __('Authentication failed.'),
        'Incorrect username'                                        => __('Authentication failed due to incorrect username.'),
        'Lookup failed'                                             => __('Authentication failed due to incorrect username.'),
        'Invalid credentials'                                       => __('Authentication failed due to incorrect credentials.'),
        'authentication not enabled'                                => __('Authentication not possible (not offered by the service)'),
        'getaddrinfo: nodename nor servname provided, or not known' => __('The hostname could not be found.'),
        'getaddrinfo: Name or service not known'                    => __('The hostname could not be found.'),
        'No route to host'                                          => __('There is no route to this host.'),
        'execution expired'                                         => __('This host cannot be reached.'),
        'Connection refused'                                        => __('The connection was refused.'),
      }
    end

    def self.config_set_verify_ssl(config, params)
      return if !config[:options]

      if params.key?(:ssl_verify)
        config[:options][:ssl_verify] = params[:ssl_verify]
      elsif config[:options][:ssl] || config[:options][:start_tls]
        config[:options][:ssl_verify] = true
      else
        config[:options][:ssl_verify] ||= false
      end
    end
  end

end
