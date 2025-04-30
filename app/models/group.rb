# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Group < ApplicationModel
  include HasDefaultModelUserRelations

  include CanBeImported
  include HasActivityStreamLog
  include ChecksClientNotification
  include ChecksHtmlSanitized
  include HasHistory
  include HasObjectManagerAttributes
  include HasCollectionUpdate
  include HasSearchIndexBackend
  include CanSelector
  include CanSearch

  include Group::Assets

  scope :sorted, -> { order(:name) }

  belongs_to :email_address, optional: true
  belongs_to :signature, optional: true
  belongs_to :parent, optional: true, class_name: 'Group'

  # workflow checks should run after before_create and before_update callbacks
  include ChecksCoreWorkflow

  core_workflow_screens 'create', 'edit'
  core_workflow_admin_screens 'create', 'edit'

  before_validation :ensure_name_last_and_parent, :check_max_depth

  before_save :update_path
  after_save :update_path_children

  validates :name, uniqueness: { case_sensitive: false }
  validates :name_last, presence: true, format: { without: %r{::}, message: __('No double colons (::) allowed, reserved delimiter') }
  validates :note, length: { maximum: 250 }
  sanitized_html :note, no_images: true

  activity_stream_permission 'admin.group'

  @@max_depth = nil # rubocop:disable Style/ClassVars

  def guess_name_last_and_parent
    split = name.split('::')
    self.name_last = split[-1]

    return if parent_id
    return if split.size == 1

    check_parent = Group.find_by(name: split[..-2].join('::'))

    if check_parent.blank?
      errors.add(:name, 'contains invalid path')
      raise ActiveRecord::RecordInvalid, self
    end

    self.parent = check_parent
  end

  def ensure_name_last_and_parent
    if persisted?
      return if name_last_changed?
      return if !name_changed?
    else
      return if name_last.present?
      return if name.blank?
    end

    guess_name_last_and_parent
  end

  def check_max_depth
    old_depth = if persisted?
                  self.class.find(id).depth
                else
                  0
                end

    new_depth = depth(force: true)
    return if new_depth < self.class.max_depth && all_children(force: true).all? { |child| new_depth + (child.depth - old_depth) < self.class.max_depth }

    raise Exceptions::UnprocessableEntity, __('This group or its children exceed the allowed nesting depth.')
  end

  def update_path
    self.name = path(force: true).join('::')
  end

  def update_path_children
    return if !saved_change_to_attribute?(:parent_id) && !saved_change_to_attribute?(:name_last)

    all_children.each do |child|
      child.update_path
      child.save!
    end
  end

  def all_parents(force: false)
    Rails.cache.fetch("Group/#{Group.latest_change}/all_parents/#{id}", force: force) do
      result     = []
      check_next = self
      (self.class.max_depth * 2).times do
        break if check_next.parent.blank?

        result << check_next.parent
        check_next = check_next.parent
      end
      result
    end
  end

  def all_children(force: false)
    return [] if !persisted?

    Rails.cache.fetch("Group/#{Group.latest_change}/all_children/#{id}", force: force) do
      result     = []
      check_next = [self]
      (self.class.max_depth * 2).times do
        break if check_next.blank?

        children = self.class.where(parent_id: check_next)
        result += children
        check_next = children
      end
      result
    end
  end

  def self.all_max_depth(force: false)
    Rails.cache.fetch("Group/#{Group.latest_change}/all_max_depth", force: force) do
      Group.select { |group| group.depth >= max_depth }
    end
  end

  def depth(force: false)
    all_parents(force: force).count
  end

  def fullname
    path.join(' › ')
  end

  def path(force: false)
    all_parents(force: force).map(&:name_last).reverse + [name_last]
  end

  def self.max_depth
    return @@max_depth if @@max_depth

    @@max_depth = ActiveRecord::Base.connection_db_config.configuration_hash[:adapter] == 'mysql2' ? 6 : 10 # rubocop:disable Style/ClassVars
  end

  def self.customer_create_groups_with_parent_ids
    Rails.cache.fetch("Group/#{Group.latest_change}/#{Setting.latest_change}/customer_create_groups_with_parent_ids") do
      result = []
      Group.where(id: Setting.get('customer_ticket_create_group_ids')).each do |group|
        result |= [group]
        result |= group.all_parents
      end
      result.pluck(:id)
    end
  end
end
