# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Manage > Channels > Email', type: :system do

  context 'when managing email channels', required_envs: %w[MAIL_ADDRESS MAIL_PASS] do

    before do
      visit '/#channels/email'
    end

    context 'when looking at the default screen' do

      it 'has correct default settings' do

        within :active_content do
          # check if postmaster filters are shown
          click 'a[href="#c-filter"]'
          expect(find('#c-filter .overview')).to have_text 'NO ENTRIES'

          # check if signatures are shown
          click 'a[href="#c-signature"]'
          expect(find('#c-signature .overview')).to have_text 'default'

        end
      end
    end

    context 'when creating new channels' do
      let(:mailbox_user)     { ENV['MAIL_ADDRESS'] }
      let(:mailbox_password) { ENV['MAIL_PASS'] }

      before do
        # Make sure the channel is loaded
        'Channel::Driver::Imap'.constantize
        # The normal timeout may be too low in slow CI environments.
        stub_const 'Channel::Driver::Imap::CHECK_ONLY_TIMEOUT', 1.minute

        # Import mail server CA certificate into the trust store.
        SSLCertificate.create!(certificate: Rails.root.join('spec/fixtures/files/imap/ca.crt').read)
      end

      it 'refuses wrong credentials' do

        click 'a[href="#c-account"]'
        click '.js-channelNew'

        in_modal do
          fill_in 'realname', with: 'My System'
          fill_in 'email',    with: "unknown_user.#{mailbox_user}"
          fill_in 'password', with: mailbox_password
          set_tree_select_value('group_id', Group.first.name)
          click '.js-submit'
          expect(page).to have_text('The server settings could not be automatically detected. Please configure them manually.')
        end

      end

      it 'accepts correct credentials' do

        click 'a[href="#c-account"]'
        click '.js-channelNew'

        in_modal timeout: 2.minutes do
          fill_in 'realname', with: 'My System'
          fill_in 'email',    with: mailbox_user
          fill_in 'password', with: mailbox_password
          set_tree_select_value('group_id', Group.first.name)
          click '.js-submit'
        end

        within :active_content do
          expect(page).to have_text(mailbox_user)
          all('.js-editInbound').last.click
          fill_in 'options::folder', with: 'nonexisting_folder'
          click '.js-submit'
          expect(page).to have_text("Mailbox doesn't exist")
        end
      end
    end

    context 'when managing filters' do
      let(:filter_name) { "Test Filter #{SecureRandom.uuid}" }

      it 'works as expected' do

        click 'a[href="#c-filter"]'
        click '.content.active a[data-type="new"]'

        in_modal do
          fill_in 'name', with: filter_name
          fill_in 'match::from::value', with: 'target'
          click '.js-submit'
        end

        expect(page).to have_text(filter_name)

        click '.content.active .table .dropdown .btn--table'
        click '.content.active .table .dropdown .js-clone'

        in_modal do
          click '.js-submit'
        end

        expect(page).to have_text("Clone: #{filter_name}")
      end

    end
  end

  context 'non editable' do

    it 'hides "Edit" links' do
      # ensure that the only existing email channel
      # has preferences == { editable: false }
      Channel.destroy_all
      create(:email_channel, preferences: { editable: false })

      visit '/#channels/email'

      # verify page has loaded
      expect(page).to have_css('#c-account h3', text: 'Inbound')
      expect(page).to have_css('#c-account h3', text: 'Outbound')

      expect(page).to have_no_css('.js-editInbound, .js-editOutbound', text: 'Edit')
    end
  end

  context 'when adding an email' do
    before do
      visit '#channels/email'
    end

    it 'one can switch between default and expert forms' do
      click '.js-channelNew'

      in_modal do
        click '.js-expert'
        expect(page).to have_text 'ORGANIZATION & DEPARTMENT NAME'
        expect(page).to have_text 'SSL/STARTTLS'
        expect(page).to have_text 'PORT'
        click '.js-close'
      end
    end

    it 'in the expert form, the port for SSL/NoSSL is set automatically only when it is default' do
      click '.js-channelNew'

      in_modal do
        click '.js-expert'
        expect(find('input[name="options::port"]').value).to eq('993')
        field = find('select[name="options::ssl"]')
        option_yes = field.find(:option, 'SSL')
        option_no = field.find(:option, 'No SSL')
        option_no.select_option
        expect(find('input[name="options::port"]').value).to eq('143')
        option_yes.select_option
        expect(find('input[name="options::port"]').value).to eq('993')
        option_no.select_option
        expect(find('input[name="options::port"]').value).to eq('143')
        port = '4242'
        fill_in 'options::port', with: port
        field.click
        expect(find('input[name="options::port"]').value).to eq(port)
        fill_in 'options::folder', with: 'testabc'
        expect(find('input[name="options::port"]').value).to eq(port)
        click '.js-close'
      end
    end

    it 'in the expert form, turning on SSL allows to turn on or off SSL verification' do
      click '.js-channelNew'

      in_modal do
        click '.js-expert'

        verify_select = find('select[name="options::ssl_verify"]')
        ssl_select    = find('select[name="options::ssl"]')

        expect(page)
          .to have_select('options::ssl_verify', selected: 'yes')
          .and have_no_text('Turning off SSL verification')

        verify_select.find(:option, 'no').select_option

        expect(page).to have_text('Turning off SSL verification')

        verify_select.find(:option, 'yes').select_option

        expect(page).to have_no_text('Turning off SSL verification')

        ssl_select.find(:option, 'No SSL').select_option

        expect(verify_select).to be_disabled

        ssl_select.find(:option, 'STARTTLS').select_option

        expect(verify_select).not_to be_disabled
      end
    end

    it 'entered values on the default form are copied to the expert form' do
      click '.js-channelNew'

      in_modal do
        name = 'Area53'
        email = 'dont@ask.com'
        password = 'f34therRa!nSplash'
        fill_in 'realname', with: name
        fill_in 'email', with: email
        fill_in 'password', with: password
        click '.js-expert'
        expect(find('input[name="options::realname"]').value).to eq(name)
        expect(find('input[name="options::email"]').value).to eq(email)
        expect(find('input[name="options::user"]').value).to eq(email)
        expect(find('input[name="options::password"]').value).to eq(password)
        click '.js-close'
      end
    end
  end

  context 'when editing inbound email settings' do
    it 'the expert form fields are not shown' do
      visit '#channels/email'
      click '.js-channelEnable'
      click '.js-editInbound'

      in_modal do
        expect(page).to have_no_text 'ORGANIZATION & DEPARTMENT NAME'
        expect(page).to have_no_text 'ORGANIZATION SUPPORT'
        expect(page).to have_no_text 'EMAIL'
      end
    end

    context 'with SSL verification off' do
      before do
        channel = Channel.in_area('Email::Account').first
        channel.options[:inbound][:options][:ssl_verify] = false
        channel.save!
      end

      it 'has SSL verification switch in inbound form' do
        visit '#channels/email'
        click '.js-channelEnable'
        click '.js-editInbound'

        in_modal do
          expect(page)
            .to have_select('options::ssl_verify', selected: 'no')
            .and have_text('Turning off SSL verification')

          verify_select = find('select[name="options::ssl_verify"]')

          verify_select.find(:option, 'yes').select_option

          expect(page).to have_no_text('Turning off SSL verification')

          verify_select.find(:option, 'no').select_option

          expect(page).to have_text('Turning off SSL verification')
        end
      end
    end
  end

  context 'when editing outbound email settings' do
    it 'has SSL verification switch in outbound form' do
      visit '#channels/email'
      click '.js-channelEnable'
      click '.js-editOutbound'

      in_modal do
        adapter_select = find('select[name="adapter"]')

        adapter_select.find(:option, 'SMTP - configure your own outgoing SMTP settings').select_option

        verify_select = find('select[name="options::ssl_verify"]')

        expect(page)
          .to have_select('options::ssl_verify', selected: 'yes')
          .and have_no_text('Turning off SSL verification')

        verify_select.find(:option, 'no').select_option

        expect(page).to have_text('Turning off SSL verification')

        verify_select.find(:option, 'yes').select_option

        expect(page).to have_no_text('Turning off SSL verification')

        port_field = find('input[name="options::port"]')

        port_field.fill_in with: '25'
        port_field.execute_script "$(this).trigger('blur')"

        expect(page).to have_css('select[name="options::ssl_verify"][disabled]')

        port_field.fill_in with: '465'
        port_field.execute_script "$(this).trigger('blur')"

        expect(page).to have_css('select[name="options::ssl_verify"]:not([disabled])')
      end
    end
  end
end
