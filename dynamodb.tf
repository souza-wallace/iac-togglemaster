# Tabela do analytics-service (AWS_DYNAMODB_TABLE).
# Nome e chave vêm de infra/dynamodb/create-table.sh no repositório da aplicação.

resource "aws_dynamodb_table" "analytics" {
  name         = "ToggleMasterAnalytics"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "event_id"

  attribute {
    name = "event_id"
    type = "S"
  }
}
