output "public_ip" {
  description = "Public IP of the worker"
  value       = aws_instance.worker.public_ip
}

output "ssh_command" {
  description = "SSH command"
  value       = "ssh ubuntu@${aws_instance.worker.public_ip}"
}

output "worker_api_url" {
  description = "Worker API URL"
  value       = "http://${aws_instance.worker.public_ip}:8080"
}

output "health_url" {
  description = "Health check URL"
  value       = "http://${aws_instance.worker.public_ip}:8080/health"
}
