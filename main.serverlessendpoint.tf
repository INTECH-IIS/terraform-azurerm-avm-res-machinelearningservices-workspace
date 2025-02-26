resource "azapi_resource" "marketplace_subscription" {
  for_each = { for k, v in var.serverless_endpoints : k => v if v.create_subscription }

  type      = "Microsoft.MachineLearningServices/workspaces/marketplaceSubscriptions@2024-10-01-preview"
  name      = coalesce(each.value.name, each.key)
  parent_id = local.aml_resource.id

  body = {
    properties = {
      modelId = each.value.model_id
    }
  }
}

resource "random_string" "serverless_endpoint_suffix" {
  for_each = { for k, v in var.serverless_endpoints : k => v if v.random_suffix }

  length  = 6
  upper   = false
  special = false
}

resource "azapi_resource" "serverless_endpoint" {
  for_each = var.serverless_endpoints

  type      = "Microsoft.MachineLearningServices/workspaces/serverlessEndpoints@2024-10-01-preview"
  name      = each.value.random_suffix ? "${coalesce(each.value.name, each.key)}-${random_string.serverless_endpoint_suffix[each.key].result}" : coalesce(each.value.name, each.key)
  location  = var.location
  parent_id = local.aml_resource.id

  body = {
    sku = {
      name = "Consumption"
    }
    properties = {
      authMode = "Key"
      modelSettings = {
        modelId = each.value.model_id
      }
    }
  }

  depends_on = [azapi_resource.marketplace_subscription]
}

data "azapi_resource_action" "serverless_endpoint_keys" {
  for_each = var.serverless_endpoints

  type                   = "Microsoft.MachineLearningServices/workspaces/serverlessEndpoints@2024-10-01-preview"
  action                 = "listKeys"
  resource_id            = azapi_resource.serverless_endpoint[each.key].id
  response_export_values = ["*"]

  depends_on = [azapi_resource.serverless_endpoint]
}
