# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class KnowledgeBase
  class PermissionsUpdate
    def initialize(object, user = nil)
      @object = object
      @user   = user
    end

    def update!(**roles_to_permissions)
      ActiveRecord::Base.transaction do
        ensure_unoverrideable_permissions!(roles_to_permissions)
        update_object(roles_to_permissions)

        next if !@object.changed_for_autosave?

        @object.save!

        update_all_children
        ensure_editable!
      end
    end

    def update_using_params!(params)
      roles_to_permissions = params[:permissions]
        .to_hash
        .transform_keys { |key| Role.find key }

      update!(**roles_to_permissions)
    end

    private

    def update_object(roles_to_permissions)
      @object.permissions.reject { |elem| roles_to_permissions.key? elem.role }.each(&:mark_for_destruction)

      roles_to_permissions.each do |role, access|
        update_object_permission(role, access)
      end
    end

    def update_object_permission(role, access)
      permission = @object.permissions.detect { |elem| elem.role == role } || @object.permissions.build(role: role)
      permission.access = access

      mark_permission_for_cleanup_if_needed(permission, parent_object_permissions)
    end

    def parent_object_permissions
      @parent_object_permissions ||= begin
        if @object.is_a? KnowledgeBase::Category
          (@object.parent || @object.knowledge_base).permissions_effective || []
        else
          []
        end
      end
    end

    def all_children
      case @object
      when KnowledgeBase::Category
        @object.self_with_children - [@object]
      when KnowledgeBase
        @object.categories.root.map(&:self_with_children).flatten
      end
    end

    def update_single_child(child)
      inherited_permissions = (child.parent || child.knowledge_base).permissions_effective

      child.permissions.each do |child_permission|
        mark_permission_for_cleanup_if_needed(child_permission, inherited_permissions)
      end

      child.changed_for_autosave? ? child.save! : child.touch # rubocop:disable Rails/SkipsModelValidations
    end

    def update_all_children
      all_children.each do |child|
        update_single_child(child)
      end
    end

    def ensure_editable!
      return if !@user
      return if KnowledgeBase::EffectivePermission.new(@user, @object).access_effective == 'editor'

      raise Exceptions::UnprocessableEntity, __('Invalid permissions, do not lock yourself out.')
    end

    def mark_permission_for_cleanup_if_needed(permission, parents)
      matching = parents.find { |elem| elem.role == permission.role }

      return if !matching
      return if matching.access == 'reader' && permission.access != 'reader'

      permission.mark_for_destruction
    end

    def ensure_unoverrideable_permissions!(new_roles_permissions)
      new_roles_permissions.each do |role, new_permission|
        ensure_single_unoverrideable_permission!(role, new_permission)
      end
    end

    def ensure_single_unoverrideable_permission!(role, new_permission)
      parent_permission = parent_object_permissions.find { |elem| elem.role == role }

      return if parent_permission.nil?
      return if parent_permission.access == 'reader'
      return if parent_permission.access == new_permission

      message = case parent_permission.access
                when 'editor'
                  __('Invalid permissions. This role has editor access to parent category. Limiting access is not effective.')
                when 'none'
                  __('Invalid permissions. This role does not have access to this category because parent category is not visible for it.')
                else
                  __('Invalid permissions.')
                end

      raise Exceptions::UnprocessableEntity, message
    end
  end
end
