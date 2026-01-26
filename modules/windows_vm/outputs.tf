output "vm_id" {
  description = "The resource ID of the Windows virtual machine."
  value       = module.vm.resource_id
}

output "vm_private_ip" {
  description = "The private IP address of the Windows virtual machine."
  value       = module.vm.network_interfaces["nic1"].private_ip_address
}
