class AddCustomFieldHiddenValuesProjectsExclusions < ActiveRecord::Migration[4.2]
  def self.up
    add_column :custom_fields, :hidden_values_projects_exclusions, :text, :null => true
  end

  def self.down
    remove_column :custom_fields, :hidden_values_projects_exclusions
  end
end
