# Massdriver Variables

variable "md_metadata" {
  type        = any
  description = "Massdriver metadata object, must include name_prefix."
}

variable "message" {
  type        = string
  description = "Message to include in the alarm description."
}

variable "monitor_action_group_id" {
  type        = string
  description = "Massdriver alarm channel Action Group ID."
}

variable "display_name" {
  type        = string
  description = "Short name to display in the Massdriver UI."
}

# Alarm Configuration

variable "alarm_name" {
  type        = string
  description = "The name of the metric alert. Must be unique within the resource group."
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group for the metric alert."
}

variable "scopes" {
  type        = set(string)
  description = "A set of resource IDs at which the metric criteria should be applied."
}

variable "severity" {
  type        = number
  description = "The severity of the metric alert. Possible values are 0, 1, 2, 3, and 4."
}

variable "frequency" {
  type        = string
  description = "The evaluation frequency represented in ISO 8601 duration format. Possible values are PT1M, PT5M, PT15M, PT30M, and PT1H."
}

variable "window_size" {
  type        = string
  description = "The period of time used to monitor alert activity, represented in ISO 8601 duration format. Must be greater than frequency. Possible values are PT1M, PT5M, PT15M, PT30M, PT1H, PT6H, PT12H, and P1D."
}

# Static Criteria Mode
# Set these for a standard threshold-based metric alert.
# Conflicts with dynamic_criteria.

variable "metric_namespace" {
  type        = string
  default     = null
  description = "The metric namespace to monitor. Required for static criteria alarms, conflicts with dynamic_criteria."
}

variable "metric_name" {
  type        = string
  default     = null
  description = "The metric name to monitor. Required for static criteria alarms, conflicts with dynamic_criteria."
}

variable "aggregation" {
  type        = string
  default     = null
  description = "The statistic that runs over the metric values. Possible values are Average, Count, Minimum, Maximum, and Total. Required when metric_name is set."
}

variable "operator" {
  type        = string
  default     = null
  description = "The criteria operator. Possible values are Equals, GreaterThan, GreaterThanOrEqual, LessThan, and LessThanOrEqual. Required when metric_name is set."
}

variable "threshold" {
  type        = number
  default     = null
  description = "The criteria threshold value that activates the alert. Required when metric_name is set."
}

variable "dimensions" {
  type = set(object({
    name     = string
    operator = string
    values   = list(string)
  }))
  default     = []
  description = "Dimensions for the static metric criteria. The dimension operator accepts Include, Exclude, or StartsWith."
}

# Dynamic Criteria Mode
# Set this for a dynamic threshold-based metric alert.
# Azure ML determines thresholds automatically based on historical metric patterns.
# Conflicts with metric_name, metric_namespace, aggregation, operator, threshold.

variable "dynamic_criteria" {
  type = object({
    metric_namespace         = string
    metric_name              = string
    aggregation              = string
    operator                 = string
    alert_sensitivity        = string
    evaluation_total_count   = optional(number)
    evaluation_failure_count = optional(number)
    ignore_data_before       = optional(string)
    dimensions = optional(set(object({
      name     = string
      operator = string
      values   = list(string)
    })), [])
  })
  default     = null
  description = "Dynamic threshold criteria configuration. Uses Azure ML to determine thresholds automatically based on historical metric patterns. Set alert_sensitivity to High, Medium, or Low. The operator must be LessThan, GreaterThan, or GreaterOrLessThan (differs from static criteria). Conflicts with static criteria variables (metric_name, metric_namespace, etc.)."
}
