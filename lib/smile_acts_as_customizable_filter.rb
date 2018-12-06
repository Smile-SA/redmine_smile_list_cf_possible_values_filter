# Smile - acts_as_customizable plugin enhancement
#
# Compatible with Redmine 2.6
#
# module Smile::RedmineOverride::ActsOverride::CustomizableOverride::FilterPossibleValues
# - #113099 Possibilité de cacher par défaut des valeurs de champ personnalisés
# - #266121 Filter multiple values custom fields
# - ClassMethods
#   - acts_as_customizable
#
# - InstanceMethods
#   - custom_values
#   - custom_field_values
#   private :
#   - filter_custom_value_possible_values

module Smile
  module RedmineOverride
    module ActsOverride
      module CustomizableOverride
        module FilterPossibleValues
          def self.prepended(base)
            acts_customizable_filter_class_methods = [
              :acts_as_customizable # 1/ OVERRIDEN RM 4.0.0 OK
            ]

            already_overriden_methods = base.methods.select{|m| m == acts_customizable_filter_class_methods[0]}
            if already_overriden_methods.any?
              method_owner = base.method(acts_customizable_filter_class_methods[0]).owner.name
              SmileTools.trace_override "#{base.name}   ALREADY overriden  < owner: #{method_owner} (SM::RMOverride::ActsOverride::CustomizableOverride::FilterPossibleValues::CMeths)",
                true,
                :redmine_smile_list_cf_possible_values_filter

              return
            end

            base.singleton_class.prepend ClassMethods

            trace_first_prefix = "#{base.name}             methods  "
            trace_prefix       = "#{' ' * (base.name.length - 5)}                     --->  "
            last_postfix       = '< (SM::RedmineOverride::ActsOverride::CustomizableOverride::FilterPossibleValues::CMeths)'

            SmileTools::trace_by_line(
              acts_customizable_filter_class_methods.select{|m| base.methods.include?(m)},
              trace_first_prefix,
              trace_prefix,
              last_postfix,
              :redmine_smile_list_cf_possible_values_filter
            )
          end # def self.included


          module ClassMethods
            # 1/ OVERRIDEN extended, RM 4.0.0 OK
            def acts_as_customizable(options = {})
              super(options)

              # We need a project to check exludes projects =>
              # {Issue, Project, Version, TimeEntry}CustomField
              return unless instance_methods.include?(:project)


              acts_customizable_filter_instance_methods = [
                :custom_values,                       # 1/ OVERRIDEN extended  RM 4.0.0 OK
                :custom_field_values,                 # 2/ OVERRIDEN rewritten RM 4.0.0 OK
                # Private
                :filter_custom_value_possible_values, # 3/ new method
              ]

              logger.debug "==>cf acts_as_customizable (with_filter) #{self.name}"

              log_spacer = ' ' * (11 - self.name.length)

              trace_first_prefix = "#{self.name} #{log_spacer}          instance_methods  "
              last_postfix       = '< (SM::RedmineOverride::ActsOverride::CustomizableOverride::FilterPossibleValues::IMeths)'


              already_overriden_methods = instance_methods.select{|m|
                  instance_method(m).owner == InstanceMethods
                }

              if already_overriden_methods.any?
                trace_prefix     = "#{self.name} #{log_spacer} ALREADY overriden"

                SmileTools.trace_override "#{trace_prefix} #{already_overriden_methods.join(', ')} #{last_postfix}",
                  true,
                  :redmine_smile_list_cf_possible_values_filter

                raise trace_first_prefix + ' already overriden methods found  ' + last_postfix
              end

              trace_prefix       = "#{' ' * (self.name.length + 5)} #{log_spacer}                 --->  "

              # Add the new instance methods overriden
              send :prepend, Smile::RedmineOverride::ActsOverride::CustomizableOverride::FilterPossibleValues::InstanceMethods

              smile_instance_methods = instance_methods.select{|m|
                  instance_method(m).owner == InstanceMethods
                }

              SmileTools::trace_by_line(
                smile_instance_methods,
                trace_first_prefix,
                trace_prefix,
                last_postfix,
                :redmine_smile_list_cf_possible_values_filter
              )

              smile_instance_methods = private_instance_methods.select{|m|
                  instance_method(m).owner == InstanceMethods
                }


              trace_first_prefix = "#{self.name} #{log_spacer}  private_instance_methods  "
              trace_prefix       = "#{' ' * (self.name.length + 5)} #{log_spacer}                 --->  "
              last_postfix       = '< (SM::RedmineOverride::ActsOverride::CustomizableOverride::FilterPossibleValues::IMeths)'

              SmileTools::trace_by_line(
                smile_instance_methods,
                trace_first_prefix,
                trace_prefix,
                last_postfix,
                :redmine_smile_list_cf_possible_values_filter
              )
            end
          end # module ClassMethods

          module InstanceMethods
            # 1/ OVERRIDEN extended, override to filter custom values afterwards
            #    RM 4.0.0 OK
            # *** ENTRY POINT #1 ***
            # Method dynamically added to ActiveRecord::Base by acts_as_customizable
            # Smile specific : cache added
            # TODO Jebat overload custom_values.build to treat other calls that we don't manage here
            def custom_values
              return @custom_values if defined?(@custom_values)

              @custom_values = super

              if @custom_values.respond_to?(:each)
                if @custom_values
                  @custom_values.each{ |cv|
                    filter_custom_value_possible_values(cv)
                  }
                end
              else
                filter_custom_value_possible_values(@custom_values)
              end

              @custom_values
            end

            # 2/ OVERRIDEN rewritten, RM 4.0.0 OK
            # Calls custom_values (the entry point)
            # Reuse the same instance variable, because already cached in original version
            # Smile specific : put the custom_value custom_field in the custom_field_value
            # Smile specific : multiple values filtered too
            def custom_field_values
              @custom_field_values ||= available_custom_fields.collect do |field|
                x = CustomFieldValue.new
                x.custom_field = field
                x.customized = self
                if field.multiple?
                  # Smile specific : custom field can be duped to filter values => find by ids
                  # Smile specific : original code ... { |v| v.custom_field == field }
                  values = custom_values.select { |v| v.custom_field.id == field.id }
                  if values.empty?
                    values << custom_values.build(:customized => self, :custom_field => field)
                    # Smile comment : new issue => new custom_value to filter
                    # Smile comment : filter first = the new and only one
                    filter_custom_value_possible_values(values.first)
                  else
                    # Smile specific NOT the original cf, the duped and filtered one
                    x.custom_field = values.first.custom_field
                  end
                  x.instance_variable_set("@value", values.map(&:value))
                else
                  # Smile specific : custom field can be duped to filter values => find by ids
                  # Smile specific : original code ... { |v| v.custom_field == field }
                  cv = custom_values.detect { |v| v.custom_field && (v.custom_field.id == field.id) }

                  if cv
                    # Smile specific NOT the original cf, the duped and filtered one
                    x.custom_field = cv.custom_field
                  else
                    cv ||= custom_values.build(:customized => self, :custom_field => field)
                    # Smile comment : new issue => new custom_value to filter
                    filter_custom_value_possible_values(cv)
                  end
                  # END -- Smile specific
                  #######################
                  x.instance_variable_set("@value", cv.value)
                end
                x.value_was = x.value.dup if x.value
                x
              end
            end

          private

            # new method, RM 2.6.10 OK
            # Filter :
            # - possible_values
            # - possible_values_localized
            def filter_custom_value_possible_values(cv)
              debug = false
              logger.debug "\\=>cf filter_custom_value_possible_values cv #{cv.id}" if debug

              cf = cv.custom_field

              ####################
              # 1/ Validity checks

              # No new cf
              return if cf.nil?

              #------------------------------------------
              # 1.1/ Data for the possible_values field ?
              #------------------------------------
              # 1.1.1/ CustomField well overriden ?
              #        New method added on CustomField by FilterPossibleValues module
              return if ! cf.respond_to?(:possible_values_unfiltered)

              #-----------------------------
              # 1.1.2/ A list custom field ?
              return if (cf.field_format != 'list')

              #-------------------------------------------------
              # 1.1.3/ Unfiltered possible values in the array ?
              if (
                cf.possible_values_unfiltered.nil? ||
                !cf.possible_values_unfiltered.is_a?(Array) ||
                cf.possible_values_unfiltered.empty?
              )
                return
              end

              #--------------------------------------
              # 1.1.4/ Possible values in the array ?
              if (
                cf.possible_values.nil? ||
                !cf.possible_values.is_a?(Array) ||
                cf.possible_values.empty?
              )
                return
              end

              #-------------------------
              # 1.2/ Already processed ?
              if (cf.possible_values.size != cf.possible_values_unfiltered.size)
                logger.debug " =>cf filter_custom_value_possible_values #{cv.id}/cf_#{cf.id}, already processed" if debug
                return
              end

              #--------------------------------------------
              # 1.3/ Data for the new hidden_values field ?
              # hidden values (Smile specific) does not exist, database migrations missing ?
              unless cf.respond_to?(:hidden_values)
                logger.error " =>cf filter_custom_value_possible_values #{cv.id}/cf_#{cf.id}, hidden_values field does not exist (database migrations not passed ?)"
                return
              end

              #----------------------------------------------------------------
              # 1.3.1/ Hidden values (Smile specific) to exclude in the array ?
              cf_hidden_values = cf.hidden_values
              if (
                cf_hidden_values.nil? ||
                !cf_hidden_values.is_a?(Array) ||
                cf_hidden_values.empty?
              )
                logger.debug " =>cf filter_custom_value_possible_values #{cv.id}/cf_#{cf.id}, NO hidden_value" if debug
                return
              end

              #############################################################
              # 2/ Find if the project is an exception to values exclusions
              project_excluded_from_hidden_values_b = false
              cf_hidden_values_projects_exclusions = nil
              if cf.respond_to?(:hidden_values_projects_exclusions)
                cf_hidden_values_projects_exclusions = cf.hidden_values_projects_exclusions
              end

              if (
                cf_hidden_values_projects_exclusions.present? &&
                cf_hidden_values_projects_exclusions.is_a?(Array) &&
                cf_hidden_values_projects_exclusions.any? &&
                # At this step, hidden value project exclusion provided with values in the array
                self.project.present?
              )
                # Method ancestors_identifiers provided by the plugin
                project_ancestors_identifiers = self.project.ancestors_identifiers

                logger.debug " =>cf filter_custom_value_possible_values #{cv.id}/cf_#{cf.id}, ancestors OK" if debug

                # See if project or parent project is in the exclusion list
                # Browse the exclusion list
                cf_hidden_values_projects_exclusions.each{ |excluded_project_identifier|
                  # logger.debug " =>cf filter_custom_value_possible_values excluded_project_identifier=#{excluded_project_identifier}"
                  next if excluded_project_identifier.strip.blank?

                  # Current project in the excluded projects list ?
                  project_excluded_from_hidden_values_b = (self.project.identifier == excluded_project_identifier)
                  if project_excluded_from_hidden_values_b
                    logger.debug "==>cf filter_custom_value_possible_values #{cv.customized_type} ##{cv.customized_id}/cf_#{cf.id}, project #{self.project.identifier} EXCLUDED" if debug
                    break
                  end

                  # Test on ancestors doable ?
                  next if project_ancestors_identifiers.empty?

                  # Current project ancestor in the excluded projects list ?
                  project_excluded_from_hidden_values_b = project_ancestors_identifiers.include?(excluded_project_identifier)
                  if project_excluded_from_hidden_values_b
                    logger.debug "==>cf filter_custom value #{cv.customized_type} ##{cv.customized_id}/cf_#{cf.id}, project #{self.project.identifier} EXCLUDED by parent" if debug
                    break
                  end
                }
              end
              # END -- 2/ Find if the project is an exception to values exclusions
              ####################################################################

              ###############################################################
              # 3/ Not filtered : project excluded for possible values filter
              if project_excluded_from_hidden_values_b
                return
              end

              ########################################################################
              # 4/ Exclude hidden values from the current cf possible_values of the cv
              # - possible_values
              # - possible_values_localized
              #   - *************************************
              #   - if PROVIDED BY the LOCALIZABLE PLUGIN
              #   - *************************************
              # possible_values_options will be generated from previous values => filtered
              filter_possible_values_localized_b = cf.respond_to?(:possible_values_localized)

              # first call AND possible_values NOT filtered
              # => localized generated unfiltered
              cf.possible_values_localized if filter_possible_values_localized_b

              cf.possible_values.reverse_each{|pv|
                next unless cf_hidden_values.include?(pv)

                value_index = cf.possible_values.index(pv)
                next unless value_index

                cf.possible_values.delete_at(value_index)
                cf.possible_values_localized.delete_at(value_index) if filter_possible_values_localized_b
              }

              # maybe here possible_values_localized have been filtered
              if cf.possible_values.size != cf.possible_values_unfiltered.size
                # Trace only if just filtered
                logger.debug "==>cf filter_custom_value_possible_values #{cv.customized_type} ##{cv.customized_id}/cf_#{cf.id} #{cf.name}, possible_values #{cf.possible_values_unfiltered.size} --> #{cf.possible_values.size}" if debug
                # logger.debug "==>cf filter_custom_value_possible_values #{cv.customized_type} ##{cv.customized_id}/cf_#{cf.id}, possible_values           --> #{cf.possible_values.inspect}" if debug
                # logger.debug "==>cf filter_custom_value_possible_values #{cv.customized_type} ##{cv.customized_id}/cf_#{cf.id}, possible_values_localized --> #{cf.possible_values_localized.inspect}" if debug && filter_possible_values_localized_b
              end
            end
          end # module InstanceMethods
        end # module FilterPossibleValues
      end # CustomizableOverride
    end # ActsOverride
  end # module RedmineOverride
end # module Smile
