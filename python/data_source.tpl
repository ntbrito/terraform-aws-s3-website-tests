data "terraform_remote_state" "$resource_name" {
    backend = "s3"
    config = {
      bucket = "$my_bucket"
      key    = "$key_name"
      region = "$my_region"
    }
}
