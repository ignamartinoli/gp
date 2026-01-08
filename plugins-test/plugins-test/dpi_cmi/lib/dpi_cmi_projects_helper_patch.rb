# This file is a part of Redmine CRM (redmine_contacts) plugin,
# customer relationship management plugin for Redmine
#
# Copyright (C) 2011-2014 Kirill Bezrukov
# http://www.redminecrm.com/
#
# redmine_contacts is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_contacts is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_contacts.  If not, see <http://www.gnu.org/licenses/>.

require_dependency 'queries_helper'

module DpiCmiProjectsHelperPatch
  # def self.included(base)
  #   base.send(:include, InstanceMethods)
  #
  #   base.class_eval do
  #     unloadable
  #
  #     # alias_method :project_settings_tabs, :cmi
  #   end
  # end
  #
  # module InstanceMethods
  #   # include ContactsHelper

    def project_settings_tabs
      tabs = super

      tabs.push({ :name => 'CMI',
                :action => :edit_project,
                :partial => 'goals/cmi_settings',
                :label => :label_cmi_settings_tab }) if @project.module_enabled?(:CMI)
      tabs

    end
  # end

end
