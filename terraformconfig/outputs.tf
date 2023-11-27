
output "aksssh" {
  value = tls_private_key.akssshkey
  sensitive = true
}
/*
output "AKS" {

  value = module.AKS
  sensitive = true
}
*/
output "kmskey" {
  value = azurerm_key_vault_key.akskmskey
  sensitive = true
}

output "kmskv" {
  value = azurerm_key_vault.akskmskv
  sensitive = true
}

