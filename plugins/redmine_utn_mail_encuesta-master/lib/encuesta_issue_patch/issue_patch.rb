require_dependency 'issue'

module EncuestaIssuePatch
module IssuePatch
  def self.included(base) # :nodoc:

    base.class_eval do
      before_save :enviar_encuesta

      def enviar_encuesta
        if self.author==User.find(435) && self.status_id_changed? && self.status_id == 5
          EncuestaMailer.deliver_encuesta(self)
        end
      end
    end

  end
end
end
