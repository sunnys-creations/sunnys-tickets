# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Ldap::User::Attributes::RoleIds::Unassigned < Sequencer::Unit::Base
  prepend ::Sequencer::Unit::Import::Common::Model::Mixin::Skip::Action

  skip_any_action

  uses :dn_roles, :ldap_config, :mapped, :instance, :dry_run
  provides :action

  def process
    # use signup/Zammad default roles
    # if no mapping was provided
    return if dn_roles.blank?

    # return if a mapping entry was found
    return if mapped[:role_ids].present?

    # use signup/Zammad default roles
    # if unassigned users should not get skipped
    return if ldap_config[:unassigned_users] != 'skip_sync'

    if instance&.active
      # deactivate instance if role assignment is lost
      if !dry_run
        instance.update!(active: false)
      end
      state.provide(:action, :deactivated)
    else
      # skip instance creation if no existing instance was found yet
      logger.info { "Skipping. No Role assignment found for login '#{mapped[:login]}'" }
      state.provide(:action, :skipped)
    end
  end
end
