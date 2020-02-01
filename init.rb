# encoding: UTF-8

require 'redmine'

###################
# 1/ Initialisation
Rails.logger.info 'o=>'
Rails.logger.info 'o=>Starting Redmine Smile List Custom Field Possible Values Filter plugin for Redmine'
Rails.logger.info "o=>Application user : #{ENV['USER']}"


plugin_name = :redmine_smile_list_cf_possible_values_filter
plugin_root = File.dirname(__FILE__)


Redmine::Plugin.register plugin_name do
  ########################
  # 2/ Plugin informations
  name 'Redmine - Smile - List CF Possible Values Filter'
  author 'Jérôme BATAILLE'
  author_url "mailto:Jerome BATAILLE <redmine-support@smile.fr>?subject=#{plugin_name}"
  description 'Adds hability to filter possibles values of Custom Fields of type list, with project exceptions'
  url "https://github.com/Smile-SA/#{plugin_name}"
  version '1.0.1'
  requires_redmine :version_or_higher => '2.6.1'

  requires_redmine_plugin :redmine_smile_base, :version_or_higher => '1.0.0'


  #######################
  # 2.1/ Plugin home page
  settings :default => HashWithIndifferentAccess.new(
    ),
    :partial => "settings/#{plugin_name}"

end # Redmine::Plugin.register ...


#################################
# 3/ Plugin internal informations
# To keep after plugin register
this_plugin = Redmine::Plugin::find(plugin_name.to_s)
plugin_version = '?.?'
# Root relative to application root
plugin_rel_root = '.'
plugin_id = 0
if this_plugin
  plugin_version  = this_plugin.version
  plugin_id       = this_plugin.__id__
  plugin_rel_root = 'plugins/' + this_plugin.id.to_s
end

# Specific should NOT be reloaded
require plugin_root + '/lib/smile_acts_as_customizable_filter'


# Do NOT put it later, in the Dispatcher.to_prepare, WILL NOT be executed for all subclasses
unless ActiveRecord::Base.include? Smile::RedmineOverride::ActsOverride::CustomizableOverride::FilterPossibleValues
#  Rails.logger.info "o=>ActiveRecord::Base.prepend Smile::RedmineOverride::ActsOverride::CustomizableOverride::FilterPossibleValues"
  ActiveRecord::Base.send(:prepend, Smile::RedmineOverride::ActsOverride::CustomizableOverride::FilterPossibleValues)
end


###############
# 4/ Dispatcher
if Rails::VERSION::MAJOR < 3
  require 'dispatcher'
end

#Executed each time the classes are reloaded
if !defined?(rails_dispatcher)
  if Rails::VERSION::MAJOR < 3
    rails_dispatcher = Dispatcher
  else
    rails_dispatcher = Rails.configuration
  end
end

###############
# 5/ to_prepare
# Executed after Rails initialization
rails_dispatcher.to_prepare do
  Rails.logger.info "o=>"
  Rails.logger.info "o=>\\__ #{plugin_name} V#{plugin_version}"

  SmileTools.reset_override_count(plugin_name)

  SmileTools.trace_override "                                plugin  #{plugin_name} V#{plugin_version}",
    true,
    :redmine_smile_list_cf_possible_values_filter


  #########################################
  # 5.1/ List of files required dynamically
  # Manage dependencies
  # To put here if we want recent source files reloaded
  # Outside of to_prepare, file changed => reloaded,
  # but with primary loaded source code
  required = [
    # lib/

    # lib/controllers

    # lib/helpers

    # lib/models
    '/lib/models/smile_models_custom_field',
    '/lib/models/smile_models_issue_custom_field',
    '/lib/models/smile_models_time_entry_custom_field',
    '/lib/models/smile_models_version_custom_field',
    '/lib/models/smile_models_project',
  ]

  if Rails.env == "development"
    ###########################
    # 5.2/ Dynamic requirements
    Rails.logger.debug "o=>require_dependency"
    required.each{ |d|
      # Reloaded each time modified
      Rails.logger.debug "o=>  #{plugin_rel_root + d}"
      require_dependency plugin_root + d
    }
    required = nil

    # Folders whose contents should be reloaded, NOT including sub-folders

#    ActiveSupport::Dependencies.autoload_once_paths.reject!{|x| x =~ /^#{Regexp.escape(plugin_root)}/}

    autoload_plugin_paths = ['/lib/controllers', '/lib/helpers', '/lib/models']

    Rails.logger.debug 'o=>'
    Rails.logger.debug "o=>autoload_paths / watchable_dirs +="
    autoload_plugin_paths.each{|p|
      new_path = plugin_root + p
      Rails.logger.debug "o=>  #{plugin_rel_root + p}"
      ActiveSupport::Dependencies.autoload_paths << new_path
      rails_dispatcher.watchable_dirs[new_path] = [:rb]
    }
  else
    ##########################
    # 5.3/ Static requirements
    Rails.logger.debug "o=>require"
    required.each{ |p|
      # Never reloaded
      Rails.logger.debug "o=>  #{plugin_rel_root + p}"
      require plugin_root + p
    }
  end
  # END -- Manage dependencies


  ##############
  # 6/ Overrides

  #***************************
  # **** 6.1/ Controllers ****
  #Rails.logger.info "o=>----- CONTROLLERS"


  #***********************
  # **** 6.2/ Helpers ****
  #Rails.logger.info "o=>----- HELPERS"

  #**********************
  # **** 6.3/ Models ****
  Rails.logger.info "o=>----- MODELS"
  unless Project.include? Smile::Models::ProjectOverride::FilterPossibleValues
    # Rails.logger.info "o=>Project.prepend Smile::Models::ProjectOverride::FilterPossibleValues"
    Project.send(:prepend, Smile::Models::ProjectOverride::FilterPossibleValues)
  end

  unless CustomField.include? Smile::Models::CustomFieldOverride::FilterPossibleValues
    # Rails.logger.info "o=>CustomField.prepend Smile::Models::CustomFieldOverride::FilterPossibleValues"
    CustomField.send(:prepend, Smile::Models::CustomFieldOverride::FilterPossibleValues)
  end

  unless VersionCustomField.include? Smile::Models::VersionCustomFieldOverride::FilterPossibleValues
    # Rails.logger.info "o=>VersionCustomField.prepend Smile::Models::VersionCustomFieldOverride::FilterPossibleValues"
    VersionCustomField.send(:prepend, Smile::Models::VersionCustomFieldOverride::FilterPossibleValues)
  end

  unless IssueCustomField.include? Smile::Models::IssueCustomFieldOverride::FilterPossibleValues
    # Rails.logger.info "o=>IssueCustomField.prepend Smile::Models::IssueCustomFieldOverride::FilterPossibleValues"
    IssueCustomField.send(:prepend, Smile::Models::IssueCustomFieldOverride::FilterPossibleValues)
  end

  unless TimeEntryCustomField.include? Smile::Models::TimeEntryCustomFieldOverride::FilterPossibleValues
    # Rails.logger.info "o=>TimeEntryCustomField.prepend Smile::Models::TimeEntryCustomFieldOverride::FilterPossibleValues"
    TimeEntryCustomField.send(:prepend, Smile::Models::TimeEntryCustomFieldOverride::FilterPossibleValues)
  end



  # keep traces if classes / modules are reloaded
  SmileTools.enable_traces(false, plugin_name)

  Rails.logger.info 'o=>/--'
end
