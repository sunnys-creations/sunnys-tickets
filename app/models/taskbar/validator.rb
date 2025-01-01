# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Taskbar::Validator
  extend ActiveSupport::Concern

  included do
    validate :validate_uniqueness, on: %i[create update]
  end

  def validate_uniqueness
    return if local_update
    return if %i[user_id app key].none? { |column| will_save_change_to_attribute?(column) }

    errors.add(:key, :taken) if taskbar_exist?
  end

  private

  def effective_user_id
    UserInfo.current_user_id.presence || user_id
  end

  def taskbar_exist?
    clause = { user_id: effective_user_id, app:, key: }
    record = Taskbar.where(clause)

    id.present? ? record.where.not(id:).exists? : record.exists?
  end
end
