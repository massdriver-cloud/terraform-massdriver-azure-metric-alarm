locals {
  is_dynamic = var.dynamic_criteria != null

  # Resolve display values for massdriver_package_alarm based on alarm mode
  display_metric_name      = local.is_dynamic ? var.dynamic_criteria.metric_name : var.metric_name
  display_metric_namespace = local.is_dynamic ? var.dynamic_criteria.metric_namespace : var.metric_namespace
  display_statistic        = local.is_dynamic ? var.dynamic_criteria.aggregation : var.aggregation
}

resource "azurerm_monitor_metric_alert" "main" {
  name                = var.alarm_name
  resource_group_name = var.resource_group_name
  scopes              = var.scopes
  description         = var.message

  severity    = var.severity
  frequency   = var.frequency
  window_size = var.window_size

  # Static criteria mode
  dynamic "criteria" {
    for_each = local.is_dynamic ? [] : [1]
    content {
      metric_namespace = var.metric_namespace
      metric_name      = var.metric_name
      aggregation      = var.aggregation
      operator         = var.operator
      threshold        = var.threshold

      dynamic "dimension" {
        for_each = { for d in var.dimensions : d.name => d }
        content {
          name     = dimension.value.name
          operator = dimension.value.operator
          values   = dimension.value.values
        }
      }
    }
  }

  # Dynamic criteria mode
  dynamic "dynamic_criteria" {
    for_each = local.is_dynamic ? [var.dynamic_criteria] : []
    content {
      metric_namespace  = dynamic_criteria.value.metric_namespace
      metric_name       = dynamic_criteria.value.metric_name
      aggregation       = dynamic_criteria.value.aggregation
      operator          = dynamic_criteria.value.operator
      alert_sensitivity = dynamic_criteria.value.alert_sensitivity

      evaluation_total_count   = dynamic_criteria.value.evaluation_total_count
      evaluation_failure_count = dynamic_criteria.value.evaluation_failure_count
      ignore_data_before       = dynamic_criteria.value.ignore_data_before

      dynamic "dimension" {
        for_each = { for d in dynamic_criteria.value.dimensions : d.name => d }
        content {
          name     = dimension.value.name
          operator = dimension.value.operator
          values   = dimension.value.values
        }
      }
    }
  }

  action {
    action_group_id = var.monitor_action_group_id
    webhook_properties = merge(
      var.md_metadata.default_tags,
      {
        alarm_id = "${var.md_metadata.name_prefix}-${local.display_metric_name}"
      }
    )
  }

  tags = var.md_metadata.default_tags

  lifecycle {
    precondition {
      condition     = (var.dynamic_criteria != null) != (var.metric_name != null)
      error_message = "Specify either dynamic_criteria (for dynamic threshold alarms) or metric_name (for static threshold alarms), but not both and not neither."
    }
    precondition {
      condition     = var.metric_name == null || (var.metric_namespace != null && var.aggregation != null && var.operator != null && var.threshold != null)
      error_message = "When metric_name is set, metric_namespace, aggregation, operator, and threshold are also required."
    }
    precondition {
      condition     = var.dynamic_criteria == null || (var.metric_name == null && var.metric_namespace == null && var.aggregation == null && var.operator == null && var.threshold == null)
      error_message = "When dynamic_criteria is set, do not set metric_name, metric_namespace, aggregation, operator, or threshold."
    }
  }
}

resource "massdriver_package_alarm" "package_alarm" {
  display_name      = var.display_name
  cloud_resource_id = azurerm_monitor_metric_alert.alarm.id
  metric {
    name      = local.display_metric_name
    namespace = local.display_metric_namespace
    statistic = local.display_statistic
  }
}
