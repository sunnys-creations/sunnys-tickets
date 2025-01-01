# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

require 'models/concerns/checks_human_changes_examples'

RSpec.describe Transaction::Notification, type: :model do
  describe 'pending ticket reminder repeats after midnight at selected time zone' do
    let(:group)  { create(:group) }
    let(:user)   { create(:agent) }
    let(:ticket) { create(:ticket, owner: user, state_name: 'open', pending_time: Time.current) }

    before do
      travel_to Time.use_zone('UTC') { Time.current.noon }

      user.groups << group
      ticket

      Setting.set('timezone_default', 'America/Santiago')
      run(ticket, user, 'reminder_reached')
      OnlineNotification.destroy_all
    end

    it 'notification not sent at UTC midnight' do
      travel_to Time.use_zone('UTC') { Time.current.end_of_day + 1.minute }

      expect { run(ticket, user, 'reminder_reached') }.not_to change(OnlineNotification, :count)
    end

    it 'notification sent at selected time zone midnight' do
      travel_to Time.use_zone('America/Santiago') { Time.current.end_of_day + 1.minute }

      expect { run(ticket, user, 'reminder_reached') }.to change(OnlineNotification, :count).by(1)
    end
  end

  # https://github.com/zammad/zammad/issues/4066
  describe 'notification sending reason may be fully translated' do
    let(:group) { create(:group) }
    let(:user)      { create(:agent, groups: [group]) }
    let(:ticket)    { create(:ticket, owner: user, state_name: 'open', pending_time: Time.current) }
    let(:reason_en) { 'You are receiving this because you are the owner of this ticket.' }
    let(:reason_de) do
      Translation.translate('de-de', reason_en).tap do |translated|
        expect(translated).not_to eq(reason_en) # rubocop:disable RSpec/ExpectInLet
      end
    end

    before do
      allow(NotificationFactory::Mailer).to receive(:deliver)
    end

    it 'notification includes English footer' do
      run(ticket, user, 'reminder_reached')

      expect(NotificationFactory::Mailer)
        .to have_received(:deliver)
        .with hash_including body: %r{#{reason_en}}
    end

    context 'when locale set to Deutsch' do
      before do
        user.preferences[:locale] = 'de-de'
        user.save
      end

      it 'notification includes German footer' do
        run(ticket, user, 'reminder_reached')

        expect(NotificationFactory::Mailer)
          .to have_received(:deliver)
          .with hash_including body: %r{#{reason_de}}
      end
    end
  end

  describe '#ooo_replacements' do
    subject(:notification_instance) { build(ticket, user) }

    let(:group)         { create(:group) }
    let(:user)          { create(:agent, :ooo, :groupable, ooo_agent: replacement_1, group: group) }
    let(:ticket)        { create(:ticket, owner: user, group: group, state_name: 'open', pending_time: Time.current) }

    context 'when replacement has access' do
      let(:replacement_1) { create(:agent, :groupable, group: group) }

      it 'is added to list' do
        replacements = Set.new

        ooo(notification_instance, user, replacements: replacements)

        expect(replacements).to include replacement_1
      end

      context 'when replacement has replacement' do
        let(:replacement_1) { create(:agent, :ooo, :groupable, ooo_agent: replacement_2, group: group) }
        let(:replacement_2) { create(:agent, :groupable, group: group) }

        it 'replacement\'s replacement added to list' do
          replacements = Set.new

          ooo(notification_instance, user, replacements: replacements)

          expect(replacements).to include replacement_2
        end

        it 'intermediary replacement is not in list' do
          replacements = Set.new

          ooo(notification_instance, user, replacements: replacements)

          expect(replacements).not_to include replacement_1
        end
      end
    end

    context 'when replacement does not have access' do
      let(:replacement_1) { create(:agent) }

      it 'is not added to list' do
        replacements = Set.new

        ooo(notification_instance, user, replacements: replacements)

        expect(replacements).not_to include replacement_1
      end

      context 'when replacement has replacement with access' do
        let(:replacement_1) { create(:agent, :ooo, ooo_agent: replacement_2) }
        let(:replacement_2) { create(:agent, :groupable, group: group) }

        it 'his replacement may be added' do
          replacements = Set.new

          ooo(notification_instance, user, replacements: replacements)

          expect(replacements).to include replacement_2
        end
      end
    end
  end

  describe 'SMTP errors' do
    let(:group)    { create(:group) }
    let(:user)     { create(:agent, groups: [group]) }
    let(:ticket)   { create(:ticket, owner: user, state_name: 'open', pending_time: Time.current) }
    let(:response) { Net::SMTP::Response.new(response_status_code, 'mocked SMTP response') }
    let(:error)    { Net::SMTPFatalError.new(response) }

    before do
      allow_any_instance_of(Net::SMTP).to receive(:start).and_raise(error)

      Service::System::SetEmailNotificationConfiguration
        .new(
          adapter:           'smtp',
          new_configuration: {}
        ).execute
    end

    context 'when there is a problem with the sending SMTP server' do
      let(:response_status_code) { 535 }

      it 'raises an eroror' do
        expect { run(ticket, user, 'reminder_reached') }
          .to raise_error(Channel::DeliveryError)
      end
    end

    context 'when there is a problem with the receiving SMTP server' do
      let(:response_status_code) { 550 }

      it 'logs the information about failed email delivery' do
        allow(Rails.logger).to receive(:info)
        run(ticket, user, 'reminder_reached')
        expect(Rails.logger).to have_received(:info)
      end
    end
  end

  it_behaves_like 'ChecksHumanChanges'

  def run(ticket, user, type)
    build(ticket, user, type).perform
  end

  def build(ticket, user, type = 'reminder_reached')
    described_class.new(
      object:           ticket.class.name,
      type:             type,
      object_id:        ticket.id,
      interface_handle: 'scheduler',
      changes:          nil,
      created_at:       Time.current,
      user_id:          user.id
    )
  end

  def ooo(instance, user, replacements: Set.new, reasons: [])
    instance.send(:ooo_replacements, user: user, replacements: replacements, ticket: ticket, reasons: reasons)
  end
end
