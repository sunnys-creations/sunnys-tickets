# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Attributes::Group < CoreWorkflow::Attributes::Base
  def values
    groups.each do |group|
      assets(group)
    end

    if groups.blank?
      ['']
    else
      groups.pluck(:id)
    end
  end

  def customer_ticket_create_group_ids
    Setting.get('customer_ticket_create_group_ids')
  end

  def groups
    @groups ||= if agent_view?
                  groups_agent
                elsif customer_view?
                  groups_customer
                else
                  groups_default
                end
  end

  def agent_view?
    @attributes.payload_class == Ticket && @attributes.user.permissions?('ticket.agent')
  end

  def customer_view?
    @attributes.payload_class == Ticket && @attributes.user.permissions?('ticket.customer') && @attributes.payload['screen'] == 'create_middle' && customer_ticket_create_group_ids.present?
  end

  def groups_agent
    if @attributes.payload['screen'] == 'create_middle'
      @attributes.user.groups_access(%w[create])
    else
      @attributes.user.groups_access(%w[create change])
    end
  end

  def groups_customer
    Group.where(id: customer_ticket_create_group_ids, active: true)
  end

  def groups_default
    Group.where(active: true)
  end

  def assets(group)
    return if @attributes.assets == false
    return if @attributes.assets[Group.to_app_model] && @attributes.assets[Group.to_app_model][group.id]

    @attributes.assets = group.assets(@attributes.assets)
  end
end
