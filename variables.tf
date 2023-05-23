variable "dream_env" {
  description = "dream app environment variables to set"
  type        = any
  default     = {}
}

variable "dream_project_dir" {
  description = "root directory of the project sources"
  type        = string
}

variable "codecommit_password_key" {
  description = "The name of the key in SSM Parameter Store that contains the CodeCommit password"
}

variable "codecommit_username" {
  description = "The username to use when authenticating to CodeCommit"
}

variable "image_name" {
  description = "name of the docker image to build without the namespace. Uses the project dir name by default"
  type        = string
  default     = null
}

variable "image_tags" {
  description = "tag of the docker image to build"
  type        = list(string)
  default     = null
}

variable "builder" {
  description = "buildpack builder to use to build the docker image. Ignored if build_with_docker is true"
  type        = string
  default     = "heroku/builder:22"
}

variable "is_public_image" {
  description = "whether the docker image should be public or not"
  type        = bool
  default     = false
}

variable "force_delete_repository" {
  description = "If true, the ECR repository will be deleted on destroy even if it contains images"
  type        = bool
  default     = true
}

variable "build_with_docker" {
  description = "If true, the docker image will be built with docker instead of buildpacks"
  type        = bool
  default     = false
}


