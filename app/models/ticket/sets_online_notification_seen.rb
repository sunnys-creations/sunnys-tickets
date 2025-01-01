# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

# Schedules a background job to update the user's ticket seen information on ticket changes.
module Ticket::SetsOnlineNotificationSeen
  extend ActiveSupport::Concern

  included do
    after_create  :ticket_set_online_notification_seen
    after_update  :ticket_set_online_notification_seen
  end

  private

  def ticket_set_online_notification_seen

    # return if we run import mode
    return false if Setting.get('import_mode')

    # set seen only if state has changes
    return false if !saved_changes?
    return false if saved_changes['state_id'].blank?

    # check if existing online notifications for this ticket should be set to seen
    return true if !OnlineNotification.seen_state?(self)

    # set all online notifications to seen
    # send background job
    TicketOnlineNotificationSeenJob.perform_later(id, updated_by_id)
  end
end
