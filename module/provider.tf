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

provider "supabase" {
  access_token = file("${path.module}/vars/supabase-access-token")
}

# Create a project resource
resource "supabase_project" "production" {
  organization_id   = file("${path.module}/vars/supabase-organization-id")
  name              = "tf-example"
  database_password = file("${path.module}/vars/supabase-database-password")
  region            = "ap-southeast-1"

  lifecycle {
    ignore_changes = [database_password]
  }
}

# Configure api settings for the linked project
resource "supabase_settings" "production" {
  project_ref = file("${path.module}/vars/supabase-linked_project")

  api = jsonencode({
    db_schema            = "public,storage,graphql_public"
    db_extra_search_path = "public,extensions"
    max_rows             = 1000
  })
}

# Vercel
provider "vercel" {
  # Or omit this for the api_token to be read
  # from the VERCEL_API_TOKEN environment variable
  api_token = file("${path.module}/vars/vercel-access-token")

  # Optional default team for all resources
  team = file("${path.module}/vars/vercel-team-id")
}

resource "vercel_project" "with_git" {
  name      = "example-project-with-git"
  framework = "nextjs"

  git_repository = {
    type = "github"
    repo = file("${path.module}/vars/vercel-gitrepo")
  }
}

# supabaseの環境変数をvercelに反映
resource "vercel_project_environment_variable" "supabase_url" {
  project_id = vercel_project.with_git.id
  key        = "NEXT_PUBLIC_SUPABASE_URL"
  value      = file("${path.module}/vars/supabase-url")
  target     = ["production"]
}

resource "vercel_project_environment_variable" "supabase_anon_key" {
  project_id = vercel_project.with_git.id
  key        = "NEXT_PUBLIC_SUPABASE_ANON_KEY"
  value      = file("${path.module}/vars/supabase-anon-key")
  target     = ["production"]
}

resource "vercel_deployment" "with_git" {
  project_id = vercel_project.with_git.id
  ref        = "main" # or a git branch
}
