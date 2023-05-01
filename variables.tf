variable "dream_env" {
  description = "dream app environment variables to set"
  type        = map(string)
  default     = {}
}

variable "dream_project_dir" {
  description = "root directory of the project sources"
  type        = string
}

variable "image_name" {
  description = "name of the docker image to build without the namespace. Uses the project dir name by default"
  type        = string
  default     = null
}

variable "image_tag" {
  description = "tag of the docker image to build"
  type        = string
  default     = "latest"
}

variable "builder" {
  description = "buildpack builder to use to build the docker image"
  type        = string
  default     = "heroku/builder:22"
}

variable "source_bucket" {
  description = "bucket to store the source code in"
  type        = string
}

variable "is_public_image" {
  description = "whether the docker image should be public or not"
  type        = bool
  default     = false
}
