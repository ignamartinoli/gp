module SiacSearchHelper
  def siac_search_form_tag(options = {}, &block)
    form_tag(
      { controller: '/search', action: 'index', id: nil },
      method: :get,
      &block
    )
  end
end
