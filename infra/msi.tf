#------------------------------------------------------------------------------
# TFE user-assigned managed identity (MSI)
#------------------------------------------------------------------------------
resource "azurerm_user_assigned_identity" "tfe" {
  name                = "${var.tag_prefix}-tfe-aks-msi"
  location            = azurerm_resource_group.tfe.location
  resource_group_name = azurerm_resource_group.tfe.name
}

resource "azurerm_role_assignment" "tfe_blob_storage" {

  scope                = azurerm_storage_account.example.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = azurerm_user_assigned_identity.tfe.principal_id
}

resource "azurerm_role_assignment" "tfe_blob_storage2" {

  scope                = azurerm_storage_account.example.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.tfe.principal_id
}


resource "azurerm_federated_identity_credential" "tfe_kube_service_account" {
  name                = "tfe-kube-service-account"
  resource_group_name =  azurerm_resource_group.tfe.name
  parent_id           = azurerm_user_assigned_identity.tfe.id
  audience            = ["api://AzureADTokenExchange"]
  
  subject             = "system:serviceaccount:terraform-enterprise:terraform-enterprise"
  issuer              = azurerm_kubernetes_cluster.example.oidc_issuer_url
}

output "azurerm_user_assigned_identity_client_id" {
    value = azurerm_user_assigned_identity.tfe.client_id
  
}

output "issues" {
  value = azurerm_kubernetes_cluster.example.oidc_issuer_url
}

output "client_id_oidc" {
  value = azurerm_user_assigned_identity.tfe.client_id
}