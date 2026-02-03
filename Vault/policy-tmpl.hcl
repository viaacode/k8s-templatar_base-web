# Allow data operations on 'secret' engine
path "secret/data/*" {
  capabilities = ["create", "update", "read", "delete"]
}

# Allow listing and metadata management on 'secret' engine
path "secret/metadata/*" {
  capabilities = ["list", "read", "delete"]
}

# Apply similar patterns to your other engines
path "kv-${ENV}/data/*" {
  capabilities = ["create", "update", "read", "delete"]
}

path "kv-${ENV}/metadata/*" {
  capabilities = ["list", "read", "delete"]
}

path "platform/data/*" {
  capabilities = ["create", "update", "read", "delete"]
}

path "platform/metadata/*" {
  capabilities = ["list", "read", "delete"]
}
