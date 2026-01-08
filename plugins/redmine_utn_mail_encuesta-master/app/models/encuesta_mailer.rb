# Redmine - project management software
# Copyright (C) 2006-2017  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

# require 'roadie'

class EncuestaMailer < ActionMailer::Base
    layout 'mailer'
    default from: 'gptic@rectorado.utn.edu.ar'

   def encuesta(solicitante,solicitud, issue)
     @solicitud=solicitud
     @issue=issue
     mail to: solicitante, subject: solicitud
   end

   def self.deliver_encuesta(issue)
     solicitante= issue.custom_field_value(45)
     if solicitante && !solicitante.blank?
       solicitud="#{issue.subject} - Notificación de finalización de trámite"
       encuesta(solicitante,solicitud, issue).deliver_later
     end
   end

end
