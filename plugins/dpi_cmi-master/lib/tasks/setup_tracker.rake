namespace :cmi do
  desc 'Create CMI needed custom tracker'
  task create_tracker: :environment do
    Tracker.find_or_create_by_name(
      name: "Objetivo",
      is_in_roadmap: 1,
      core_fields: ["assigned_to_id", "category_id", "fixed_version_id", "parent_issue_id",
        "start_date", "due_date", "estimated_hours", "done_ratio", ""]
    )
    Tracker.find_or_create_by_name(
      name: "Indicador",
      is_in_roadmap: 1,
      core_fields: []
    )
  end

  desc 'Create CMI needed kind of goal'
  task create_goal_kind: :environment do
    if tracker = Tracker.where(name: "Objetivo").first
      params = {
        name: "Perspectiva",
        field_format: "list",
        multiple: false,
        searchable: false,
        default_value: "",
        is_required: true, is_for_all: true, is_filter: false,
        possible_values: "Financiera\r\nCliente\r\nProceso Interno\r\nAprendizaje y Crecimiento",
        tracker_ids: [tracker.id]
      }

      CustomField.new_subclass_instance("IssueCustomField", params).save
    end
  end

  desc 'Create CMI needed goal indicators'
  task create_goal_indicators: :environment do
    if tracker = Tracker.where(name: "Indicador").first
      params = {
        name: "Avances de Indicadores",
        field_format: "list",
        multiple: false,
        searchable: false,
        default_value: "",
        is_required: false, is_for_all: true, is_filter: false,
        possible_values: "Semaforo Min\r\nSemaforo Med\r\nSemaforo Max",
        tracker_ids: [tracker.id]
      }

      CustomField.new_subclass_instance("IssueCustomField", params).save
    end
  end
end
