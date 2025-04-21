terraform {
  cloud {
    hostname = "tfe11.aws.munnep.com"
    organization = "test"

    workspaces {
      name = "test"
    }
  }
}

resource "null_resource" "test" {}