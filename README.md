# Azure Metric Alarm Terraform module

Terraform module that creates a [Massdriver](https://www.massdriver.cloud/)-integrated Azure Monitor metric alert. Supports both static threshold alarms and dynamic threshold alarms (Azure ML-based) in a single module.

This module is designed to be used alongside [`terraform-massdriver-azure-alarm-channel`](https://github.com/massdriver-cloud/terraform-massdriver-azure-alarm-channel), which creates the Action Group that alarm notifications are published to.

## Features

- Creates an Azure Monitor metric alert with Action Group integration for alarm notifications
- Supports static threshold alarms (`metric_name`, `metric_namespace`, `aggregation`, `operator`, `threshold`)
- Supports dynamic threshold alarms (`dynamic_criteria`) where Azure ML determines thresholds based on historical metric patterns
- Validates inputs at plan time to enforce mutual exclusivity between the two modes
- Registers the alarm with Massdriver for UI visibility via `massdriver_package_alarm`

## Usage

### Static threshold alarm

```hcl
module "alarm_channel" {
  source = "massdriver-cloud/azure-alarm-channel/massdriver"

  md_metadata = var.md_metadata
}

module "cpu_alarm" {
  source = "massdriver-cloud/azure-metric-alarm/massdriver"

  alarm_name   = "${var.md_metadata.name_prefix}-cpu-high"
  display_name = "CPU High"
  message      = "CPU utilization exceeded threshold"

  monitor_action_group_id = module.alarm_channel.id
  md_metadata             = var.md_metadata
  resource_group_name     = azurerm_resource_group.main.name
  scopes                  = [azurerm_linux_virtual_machine.main.id]

  severity    = 2
  frequency   = "PT5M"
  window_size = "PT15M"

  metric_namespace = "Microsoft.Compute/virtualMachines"
  metric_name      = "Percentage CPU"
  aggregation      = "Average"
  operator         = "GreaterThanOrEqual"
  threshold        = 80
}
```

### Dynamic threshold alarm

```hcl
module "latency_alarm" {
  source = "massdriver-cloud/azure-metric-alarm/massdriver"

  alarm_name   = "${var.md_metadata.name_prefix}-latency-anomaly"
  display_name = "Latency Anomaly"
  message      = "Request latency is outside normal range"

  monitor_action_group_id = module.alarm_channel.id
  md_metadata             = var.md_metadata
  resource_group_name     = azurerm_resource_group.main.name
  scopes                  = [azurerm_app_service.main.id]

  severity    = 2
  frequency   = "PT5M"
  window_size = "PT15M"

  dynamic_criteria = {
    metric_namespace         = "Microsoft.Web/sites"
    metric_name              = "HttpResponseTime"
    aggregation              = "Average"
    operator                 = "GreaterThan"
    alert_sensitivity        = "Medium"
    evaluation_total_count   = 4
    evaluation_failure_count = 4
  }
}
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.68.0 |
| <a name="provider_massdriver"></a> [massdriver](#provider\_massdriver) | 1.3.4 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_monitor_metric_alert.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert) | resource |
| [massdriver_package_alarm.package_alarm](https://registry.terraform.io/providers/massdriver-cloud/massdriver/latest/docs/resources/package_alarm) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aggregation"></a> [aggregation](#input\_aggregation) | The statistic that runs over the metric values. Possible values are Average, Count, Minimum, Maximum, and Total. Required when metric\_name is set. | `string` | `null` | no |
| <a name="input_alarm_name"></a> [alarm\_name](#input\_alarm\_name) | The name of the metric alert. Must be unique within the resource group. | `string` | n/a | yes |
| <a name="input_dimensions"></a> [dimensions](#input\_dimensions) | Dimensions for the static metric criteria. The dimension operator accepts Include, Exclude, or StartsWith. | <pre>set(object({<br>    name     = string<br>    operator = string<br>    values   = list(string)<br>  }))</pre> | `[]` | no |
| <a name="input_display_name"></a> [display\_name](#input\_display\_name) | Short name to display in the Massdriver UI. | `string` | n/a | yes |
| <a name="input_dynamic_criteria"></a> [dynamic\_criteria](#input\_dynamic\_criteria) | Dynamic threshold criteria configuration. Uses Azure ML to determine thresholds automatically based on historical metric patterns. Set alert\_sensitivity to High, Medium, or Low. The operator must be LessThan, GreaterThan, or GreaterOrLessThan (differs from static criteria). Conflicts with static criteria variables (metric\_name, metric\_namespace, etc.). | <pre>object({<br>    metric_namespace         = string<br>    metric_name              = string<br>    aggregation              = string<br>    operator                 = string<br>    alert_sensitivity        = string<br>    evaluation_total_count   = optional(number)<br>    evaluation_failure_count = optional(number)<br>    ignore_data_before       = optional(string)<br>    dimensions = optional(set(object({<br>      name     = string<br>      operator = string<br>      values   = list(string)<br>    })), [])<br>  })</pre> | `null` | no |
| <a name="input_frequency"></a> [frequency](#input\_frequency) | The evaluation frequency represented in ISO 8601 duration format. Possible values are PT1M, PT5M, PT15M, PT30M, and PT1H. | `string` | n/a | yes |
| <a name="input_md_metadata"></a> [md\_metadata](#input\_md\_metadata) | Massdriver metadata object, must include name\_prefix. | `any` | n/a | yes |
| <a name="input_message"></a> [message](#input\_message) | Message to include in the alarm description. | `string` | n/a | yes |
| <a name="input_metric_name"></a> [metric\_name](#input\_metric\_name) | The metric name to monitor. Required for static criteria alarms, conflicts with dynamic\_criteria. | `string` | `null` | no |
| <a name="input_metric_namespace"></a> [metric\_namespace](#input\_metric\_namespace) | The metric namespace to monitor. Required for static criteria alarms, conflicts with dynamic\_criteria. | `string` | `null` | no |
| <a name="input_monitor_action_group_id"></a> [monitor\_action\_group\_id](#input\_monitor\_action\_group\_id) | Massdriver alarm channel Action Group ID. | `string` | n/a | yes |
| <a name="input_operator"></a> [operator](#input\_operator) | The criteria operator. Possible values are Equals, GreaterThan, GreaterThanOrEqual, LessThan, and LessThanOrEqual. Required when metric\_name is set. | `string` | `null` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The name of the resource group for the metric alert. | `string` | n/a | yes |
| <a name="input_scopes"></a> [scopes](#input\_scopes) | A set of resource IDs at which the metric criteria should be applied. | `set(string)` | n/a | yes |
| <a name="input_severity"></a> [severity](#input\_severity) | The severity of the metric alert. Possible values are 0, 1, 2, 3, and 4. | `number` | n/a | yes |
| <a name="input_threshold"></a> [threshold](#input\_threshold) | The criteria threshold value that activates the alert. Required when metric\_name is set. | `number` | `null` | no |
| <a name="input_window_size"></a> [window\_size](#input\_window\_size) | The period of time used to monitor alert activity, represented in ISO 8601 duration format. Must be greater than frequency. Possible values are PT1M, PT5M, PT15M, PT30M, PT1H, PT6H, PT12H, and P1D. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_id"></a> [id](#output\_id) | The ID of the Azure Monitor metric alert. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Authors

Module is maintained by [Massdriver, Inc.](https://www.massdriver.cloud/)

## License

Apache 2 Licensed. See [LICENSE](LICENSE) for full details.
