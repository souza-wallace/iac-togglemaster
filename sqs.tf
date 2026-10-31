# Fila Standard: o evaluation-service envia, o analytics-service consome (AWS_SQS_URL).

resource "aws_sqs_queue" "events" {
  name                       = "${var.project}-events"
  visibility_timeout_seconds = 30
  receive_wait_time_seconds  = 20
  sqs_managed_sse_enabled    = true
}
