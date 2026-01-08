module SiacUserPatch
  def self.included(base)
    base.send(:include, SiacUser)
  end
end
