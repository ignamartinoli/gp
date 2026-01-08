module UtnMailing
  module MailerPatch
    def issue_edit(user, journal)
      @journal = journal
      @issue = journal.journalized
      @user = user
      @project = @issue.project

      vista_personalizada = File.join(Rails.root, 'plugins', 'utn_mailing', 'app', 'views')
      prepend_view_path vista_personalizada
      Rails.logger.warn "UTN_MAILING: usando vista personalizada en #{vista_personalizada}"

      redmine_headers 'Project' => @project.identifier,
                      'Issue-Id' => @issue.id,
                      'Issue-Author' => @issue.author.login
      redmine_headers 'Issue-Assignee' => @issue.assigned_to.login if @issue.assigned_to

      message_id journal
      references @issue

      @journal_details = journal.visible_details
      @issue_url = url_for(controller: 'issues', action: 'show', id: @issue, anchor: "change-#{journal.id}")

      s = "[#{@project.name} - #{@issue.tracker.name} ##{@issue.id}] "
      s << "(#{@issue.status.name}) " if journal.new_value_for('status_id')
      s << @issue.subject

      # Obtengo todos los emails extra del usuario
      extra_emails = @user.email_addresses.pluck(:address)

      # Armo la lista completa de destinatarios: email principal + emails extras (sin duplicados)
      recipients = ([ @user.mail ] + extra_emails).uniq

      mail(
        to: recipients,
        subject: s,
        from: '"NO RESPONDER - GP PLANEAMIENTO" <gp-planeamiento@rec.utn.edu.ar>'
      ) do |format|
        format.text
        format.html
      end
    end
  end
end
