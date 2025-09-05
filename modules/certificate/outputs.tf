output "secret_uri" {
  description = "The URI of the certificate secret in Key Vault (versionless)."
  value       = azapi_resource.certificate_deployment_script.output.properties.outputs.secretUrl
}
