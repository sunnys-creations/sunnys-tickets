# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Overview < ApplicationModel
  include HasDefaultModelUserRelations

  include ChecksClientNotification
  include ChecksConditionValidation
  include CanSeed
  include CanPriorization
  include HasSearchIndexBackend
  include CanSelector
  include CanSearch

  include Overview::Assets
  include Overview::TriggersSubscriptions

  has_and_belongs_to_many :roles, after_add: :cache_update, after_remove: :cache_update, class_name: 'Role'
  has_and_belongs_to_many :users, after_add: :cache_update, after_remove: :cache_update, class_name: 'User'
  store     :condition
  store     :order
  store     :view
  validates :name, presence: true
  validates :roles, presence: true

  has_many :overview_sortings, class_name: 'User::OverviewSorting', dependent: :destroy
  association_attributes_ignored :overview_sortings

  before_create :fill_link_on_create
  before_update :fill_link_on_update

  def self.attribute_to_references_hash
    deletable_attributes = ObjectManager::Attribute.where(editable: true, object_lookup_id: ObjectLookup.by_name('Ticket')).pluck(:name)

    Overview.pluck(:name, :order, :view, :group_by).each_with_object({}) do |(name, order, view, group_by), result|
      fields = Array.wrap(view.except('view_mode_default').values).flatten
      fields << order['by']
      fields << group_by
      fields = fields.compact_blank.uniq

      fields.each do |field|
        next if deletable_attributes.exclude?(field)

        result["ticket.#{field}"] ||= { 'Overview' => [] }
        result["ticket.#{field}"]['Overview'] << name
      end
    end
  end

  private

  def fill_link_on_create
    self.link = if link.present?
                  link_name(link)
                else
                  link_name(name)
                end
    true
  end

  def fill_link_on_update
    return true if !changes['name'] && !changes['link']

    self.link = if link.present?
                  link_name(link)
                else
                  link_name(name)
                end
    true
  end

  def link_name(name)
    local_link = name.downcase
    local_link = local_link.parameterize(separator: '_')
    local_link.gsub!(%r{\s}, '_')
    local_link.squeeze!('_')
    local_link = CGI.escape(local_link)
    if local_link.blank?
      local_link = id || SecureRandom.uuid
    end
    check = true
    count = 0
    local_lookup_link = local_link
    while check
      count += 1
      exists = Overview.find_by(link: local_lookup_link)
      if exists && exists.id != id
        local_lookup_link = "#{local_link}_#{count}"
      else
        check = false
        local_link = local_lookup_link
      end
    end
    local_link
  end

end
