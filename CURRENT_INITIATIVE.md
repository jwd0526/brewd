# Plan

Ideas/planning for brewd

## Development Process (quasi-agile)

1. Miro kanban
2. Weekly refinement/progress (tennatively Mondays or as needed)
   1. Add items to backlog/talk about progress
   2. Talk about dev for the week
   3. Move items in kanban
   4. Problems/concerns discussion
   5. Update kanban
3. ```main``` branch is existing release/stage of development
   1. Changes will be brought by a merge request with mandatory reviewal
   2. CI/CD will run on main triggered by merge
   3. NO force pushes to main

## Phase 1 Features

For phase 1, users should be able to do the following:

### Account Creation

Users should be able to create an account, login/logout and update their user. The backend should retrieve data from database per request

#### Frontend

1. Login screen/create account
2. Navigation to an authenticated view on login (should have a logout button)
3. Update password/email/username
4. Loading components/state

#### API Layer

1. Create users route: POST /api/users
2. Modify user: PUT api/users/:id
   1. Users designated by their ULID: [ULID Spec](https://github.com/oklog/ulid)
3. Login route: POST /api/auth/login
   1. JWT validation
4. Logout route: POST /api/auth/logout
   1. Removes token

#### Database

1. Define schema for user
2. sqlc.yaml file for config
3. ```sqlc compile && sqlc generate``` for query wrappers

## Phase 2 Outline

TBD...