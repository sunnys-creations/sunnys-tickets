# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Controllers::TicketsSharedDraftStartsControllerPolicy < Controllers::ApplicationControllerPolicy
  def index?
    access?(__method__)
  end

  def show?
    access?(__method__)
  end

  def create?
    access?(__method__)
  end

  def update?
    access?(__method__)
  end

  def destroy?
    access?(__method__)
  end

  def import_attachments?
    access?(__method__)
  end

  private

  def access?(_method)
    user.permissions?('ticket.agent') && user.group_ids_access('create').present?
  end
end
