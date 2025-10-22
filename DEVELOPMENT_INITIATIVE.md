# Plan

Development process, planning, and current initiative

## Development Process
We follow a lightweight agile workflow centered around a Miro kanban board and weekly sync meetings.

### Kanban Board

All work is tracked on our [Miro Board](https://miro.com/app/board/uXjVJ20Dk1s=/?share_link_id=99270898306).

### Weekly Sync

When: Mondays (or as needed)

#### Agenda

- Review progress from previous week
- Discuss upcoming development priorities
- Add new items to backlog
- Update kanban board status
- Address blockers and concerns

### Branching & Merging

`main` branch: Represents the current stable release/stage
Feature branches: Create branches for new features or fixes
Pull requests: All changes to `main` require:

1. A pull/merge request
2. Mandatory code review and approval
3. Passing CI/CD checks

**Protection**: Force pushes to main are prohibited

## CI/CD

Automated pipelines run on any branch when changes are pushed. These include:

1. Linting for go, next and react, and Dockerfiles
2. Autoformatting using gofmt and prettier

This ensures code quality and deployment readiness before changes reach production

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