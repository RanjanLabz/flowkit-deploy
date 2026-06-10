output "public_ip" {
  description = "Public IP of the worker"
  value       = google_compute_instance.worker.network_interface[0].access_config[0].nat_ip
}

output "ssh_command" {
  description = "SSH command"
  value       = "ssh ubuntu@${google_compute_instance.worker.network_interface[0].access_config[0].nat_ip}"
}

output "worker_api_url" {
  description = "Worker API URL"
  value       = "http://${google_compute_instance.worker.network_interface[0].access_config[0].nat_ip}:8080"
}

output "health_url" {
  description = "Health check URL"
  value       = "http://${google_compute_instance.worker.network_interface[0].access_config[0].nat_ip}:8080/health"
}
