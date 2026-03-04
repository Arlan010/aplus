# Aplus

Flutter + Supabase application for students and school pupils.

## Features

- registration, login, profile editing, password reset
- grade diary by subject
- GPA calculation based on saved grades
- required exam score calculation for a target average
- support for `100` and `5` point grade views

## Data Model

- `profiles`: user profile and preferred grade view
- `subjects`: user subjects
- `grades`: grades linked to a user and subject

The SQL schema for Supabase is stored in [supabase/schema.sql](/c:/Users/danat/github_projects/aplus/supabase/schema.sql).
