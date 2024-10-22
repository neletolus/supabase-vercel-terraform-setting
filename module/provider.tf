terraform {
  required_providers {
    supabase = {
      source  = "supabase/supabase"
      version = "~> 1.0"
    }
    vercel = {
      source  = "vercel/vercel"
      version = "~> 2.0"
    }
  }
}

variable "supabase_access_token" {}
variable "supabase_organization_id" {}
variable "supabase_database_password" {}
variable "supabase_linked_project" {}
variable "supabase_url" {}
variable "supabase_anon_key" {}

variable "vercel_access_token" {}
variable "vercel_team_id" {}
variable "vercel_gitrepo" {}

provider "supabase" {
  access_token = var.supabase_access_token
}

# Create a project resource
resource "supabase_project" "production" {
  organization_id   = var.supabase_organization_id
  name              = "tf-example"
  database_password = var.supabase_database_password
  region            = "ap-southeast-1"

  lifecycle {
    ignore_changes = [database_password]
  }
}

# Configure api settings for the linked project
resource "supabase_settings" "production" {
  project_ref = var.supabase_linked_project

  api = jsonencode({
    db_schema            = "public,storage,graphql_public"
    db_extra_search_path = "public,extensions"
    max_rows             = 1000
  })
}

# Vercel
provider "vercel" {
  api_token = var.vercel_access_token
  team      = var.vercel_team_id
}

resource "vercel_project" "with_git" {
  name      = "example-project-with-git"
  framework = "nextjs"

  git_repository = {
    type = "github"
    repo = var.vercel_gitrepo
  }
}

# supabaseの環境変数をvercelに反映
resource "vercel_project_environment_variable" "supabase_url" {
  project_id = vercel_project.with_git.id
  key        = "NEXT_PUBLIC_SUPABASE_URL"
  value      = var.supabase_url
  target     = ["production"]
}

resource "vercel_project_environment_variable" "supabase_anon_key" {
  project_id = vercel_project.with_git.id
  key        = "NEXT_PUBLIC_SUPABASE_ANON_KEY"
  value      = var.supabase_anon_key
  target     = ["production"]
}

resource "vercel_deployment" "with_git" {
  project_id = vercel_project.with_git.id
  ref        = "main" # or a git branch
}
