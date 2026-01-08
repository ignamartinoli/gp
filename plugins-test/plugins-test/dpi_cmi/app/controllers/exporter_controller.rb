class ExporterController < ApplicationController
  unloadable
  helper :journals
  helper :projects
  include ProjectsHelper
  helper :custom_fields
  helper :goals
  include CustomFieldsHelper
  helper :issue_relations
  include IssueRelationsHelper
  helper :watchers
  include WatchersHelper
  helper :attachments
  include AttachmentsHelper
  helper :queries
  include QueriesHelper
  helper :repositories
  include RepositoriesHelper
  helper :sort
  include SortHelper
  include IssuesHelper
  helper :issues
  helper :timelog
  include ApplicationHelper

  def to_doc
  	find_issue
  	@project=@issue.project
    @journals = @issue.journals.includes(:user, :details).reorder("#{Journal.table_name}.id ASC").all
    @journals_others=get_children_journals(@issue, @issue.id)
    @journals.each_with_index {|j,i| j.indice = i+1}
    @journals_others.each_with_index {|j,i| j.indice = i+1}
    @journals.reject!(&:private_notes?) unless User.current.allowed_to?(:view_private_notes, @issue.project)
    @journals_others.reject!(&:private_notes?) unless User.current.allowed_to?(:view_private_notes, @issue.project)
    Journal.preload_journals_details_custom_fields(@journals)
    Journal.preload_journals_details_custom_fields(@journals_others)
    # TODO: use #select! when ruby1.8 support is dropped
    @journals.reject! {|journal| !journal.notes? && journal.visible_details.empty?}
    @journals_others.reject! {|journal| !journal.notes? && journal.visible_details.empty?}
    @journals.reverse! if User.current.wants_comments_in_reverse_order?
    @journals_others=@journals_others.sort_by{|e| e[:created_on]}
    @journals_others.reverse! if User.current.wants_comments_in_reverse_order?

    @changesets = @issue.changesets.visible.all
    @changesets.reverse! if User.current.wants_comments_in_reverse_order?
    @relations = @issue.relations.select {|r| r.other_issue(@issue) && r.other_issue(@issue).visible? }
    @allowed_statuses = @issue.new_statuses_allowed_to(User.current)
    @edit_allowed = User.current.allowed_to?(:edit_issues, @project)
    @priorities = IssuePriority.active
    @time_entry = TimeEntry.new(:issue => @issue, :project => @issue.project)
    @relation = IssueRelation.new
  	respond_to do |format|
  		format.docx do
  		  render docx: 'to_doc', filename: "#{@issue.tracker.name}_#{@issue.id}-#{@issue.subject.truncate(30, separator: ' ', omission:'(...)')}.docx"
  		end
	  end
  end

  def gestion_to_doc
  	find_issue
  	@project=@issue.project
    @journals = @issue.journals.includes(:user, :details).reorder("#{Journal.table_name}.id ASC").all
    @journals_others=get_children_journals(@issue, @issue.id)
    @journals.each_with_index {|j,i| j.indice = i+1}
    @journals_others.each_with_index {|j,i| j.indice = i+1}
    @journals.reject!(&:private_notes?) unless User.current.allowed_to?(:view_private_notes, @issue.project)
    @journals_others.reject!(&:private_notes?) unless User.current.allowed_to?(:view_private_notes, @issue.project)
    Journal.preload_journals_details_custom_fields(@journals)
    Journal.preload_journals_details_custom_fields(@journals_others)
    # TODO: use #select! when ruby1.8 support is dropped
    @journals.reject! {|journal| !journal.notes? && journal.visible_details.empty?}
    @journals_others.reject! {|journal| !journal.notes? && journal.visible_details.empty?}
    @journals.reverse! if User.current.wants_comments_in_reverse_order?
    @journals_others=@journals_others.sort_by{|e| e[:created_on]}
    @journals_others.reverse! if User.current.wants_comments_in_reverse_order?

    @changesets = @issue.changesets.visible.all
    @changesets.reverse! if User.current.wants_comments_in_reverse_order?
    @relations = @issue.relations.select {|r| r.other_issue(@issue) && r.other_issue(@issue).visible? }
    @allowed_statuses = @issue.new_statuses_allowed_to(User.current)
    @edit_allowed = User.current.allowed_to?(:edit_issues, @project)
    @priorities = IssuePriority.active
    @time_entry = TimeEntry.new(:issue => @issue, :project => @issue.project)
    @relation = IssueRelation.new
  	respond_to do |format|
  		format.docx do
  		  render docx: 'gestion_to_doc', filename: "#{@issue.tracker.name}_#{@issue.id}-#{@issue.subject.truncate(30, separator: ' ', omission:'(...)')}.docx"
  		end
	  end
  end

private
  def retrieve_previous_and_next_issue_ids
    retrieve_query_from_session
    if @query
      sort_init(@query.sort_criteria.empty? ? [['id', 'desc']] : @query.sort_criteria)
      sort_update(@query.sortable_columns, 'issues_index_sort')
      limit = 500
      issue_ids = @query.issue_ids(:order => sort_clause, :limit => (limit + 1), :include => [:assigned_to, :tracker, :priority, :category, :fixed_version])
      if (idx = issue_ids.index(@issue.id)) && idx < limit
        if issue_ids.size < 500
          @issue_position = idx + 1
          @issue_count = issue_ids.size
        end
        @prev_issue_id = issue_ids[idx - 1] if idx > 0
        @next_issue_id = issue_ids[idx + 1] if idx < (issue_ids.size - 1)
      end
    end
  end

  def get_children_journals(issue, id_omitir)
    journals=[]
    if issue.visible?
      journals = issue.journals.includes(:user, :details).reorder("#{Journal.table_name}.created_on ASC").all unless issue.id==id_omitir
      issue.children.each do |child|
        journals+=get_children_journals(child, id_omitir) if child.visible?
      end
    end
    return journals
  end

end
