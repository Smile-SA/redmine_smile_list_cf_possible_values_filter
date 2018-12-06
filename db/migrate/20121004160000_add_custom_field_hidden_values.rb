class AddCustomFieldHiddenValues < ActiveRecord::Migration[4.2]
  def self.up
    add_column :custom_fields, :hidden_values, :text, :null => true
  end

  def self.down
    remove_column :custom_fields, :hidden_values
  end
end
