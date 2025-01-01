# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Channel::Driver::Smtp
  include Channel::EmailHelper

  # we're using the same timeouts like in Net::SMTP gem
  #   but we would like to have the possibility to mock it for tests
  DEFAULT_OPEN_TIMEOUT = 30.seconds
  DEFAULT_READ_TIMEOUT = 60.seconds

=begin

  instance = Channel::Driver::Smtp.new
  instance.send(
    {
      host:                 'some.host',
      port:                 25,
      enable_starttls_auto: true, # optional
      openssl_verify_mode:  'none', # optional
      user:                 'someuser',
      password:             'somepass'
      authentication:       nil, # nil, autodetection - to use certain schema use 'plain', 'login', 'xoauth2' or 'cram_md5'
    },
    mail_attributes,
    notification
  )

=end

  def deliver(options, attr, notification = false)

    # return if we run import mode
    return if Setting.get('import_mode')

    # set smtp defaults
    if !options.key?(:port) || options[:port].blank?
      options[:port] = 25
    end
    if !options.key?(:ssl) && options[:port].to_i == 465
      options[:ssl] = true
    end
    if !options.key?(:domain)
      # set fqdn, if local fqdn - use domain of sender
      fqdn = Setting.get('fqdn')
      if fqdn =~ %r{(localhost|\.local^|\.loc^)}i && (attr['from'] || attr[:from])
        domain = Mail::Address.new(attr['from'] || attr[:from]).domain
        if domain
          fqdn = domain
        end
      end
      options[:domain] = fqdn
    end
    if !options.key?(:enable_starttls_auto)
      options[:enable_starttls_auto] = true
    end
    ssl_verify_mode = if options[:openssl_verify_mode].present?
                        options[:openssl_verify_mode]
                      else
                        options.fetch(:ssl_verify, true) ? 'peer' : 'none'
                      end

    # set system_bcc of config if defined
    system_bcc = Setting.get('system_bcc')
    email_address_validation = EmailAddressValidation.new(system_bcc)
    if system_bcc.present? && email_address_validation.valid?
      attr[:bcc] ||= ''
      attr[:bcc] += ', ' if attr[:bcc].present?
      attr[:bcc] += system_bcc
    end
    attr = prepare_idn_outbound(attr)

    mail = Channel::EmailBuild.build(attr, notification)
    smtp_params = {
      openssl_verify_mode:  ssl_verify_mode,
      address:              options[:host],
      port:                 options[:port],
      domain:               options[:domain],
      enable_starttls_auto: options[:enable_starttls_auto],
      open_timeout:         DEFAULT_OPEN_TIMEOUT,
      read_timeout:         DEFAULT_READ_TIMEOUT,
    }

    # set ssl if needed
    if options[:ssl].present?
      smtp_params[:ssl] = options[:ssl]
    end

    # add authentication only if needed
    if options[:user].present?
      smtp_params[:user_name] = options[:user]
      smtp_params[:password] = options[:password]
      smtp_params[:authentication] = options[:authentication]
    end

    Certificate::ApplySSLCertificates.ensure_fresh_ssl_context if options[:ssl] || options[:enable_starttls_auto]

    mail.delivery_method :smtp, smtp_params
    mail.deliver
  end
end
