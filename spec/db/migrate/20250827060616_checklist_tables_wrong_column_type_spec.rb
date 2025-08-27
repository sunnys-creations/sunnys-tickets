# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ChecklistTablesWrongColumnType, type: :db_migration do
  describe 'with PostgreSQL backend', db_adapter: :postgresql, db_strategy: :reset do
    before do
      change_column :checklists, :sorted_item_ids, :text, null: true, array: true
      change_column :checklist_templates, :sorted_item_ids, :text, null: true, array: true

      Checklist.reset_column_information
      ChecklistTemplate.reset_column_information
    end

    it 'migrates column array type' do
      expect { migrate }
        .to change { Checklist.columns.find { |c| c.name == 'sorted_item_ids' }.type }.from(:text).to(:string)
        .and change { ChecklistTemplate.columns.find { |c| c.name == 'sorted_item_ids' }.type }.from(:text).to(:string)
    end
  end

  describe 'with MariaDB backend', db_adapter: :mysql do
    it 'does not migrate column array type' do
      expect { migrate }
        .to not_change { Checklist.columns.find { |c| c.name == 'sorted_item_ids' }.type }.from(:json)
        .and not_change { ChecklistTemplate.columns.find { |c| c.name == 'sorted_item_ids' }.type }.from(:json)
    end
  end
end
