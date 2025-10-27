# Features

## Tech

- Not a webapp (for now)

## Functional

- Users can submit a post for a coffee they've drinken

## Navigation

- Discover | Activity | Profile | Notification | Profile

### User Profile

- User pic
- Stats
- Posts
- Join Date
- Location
- Photos

## Onjects

### Post

CREATE TABLE post {
    id ulid,
    owner foreign key user,
    title,
    description,
    brew foreign key brew,
    tagged_friends user[],
    likes user[],
    {crud fields}
}

### Comment

CREATE TABLE comment {
    id ulid,
    parent null | key comment
    owner user,
    likes user[],
    comments comment[],
    description text,
    {crud fields}
}


### User

CREATE TABLE user {
    ...from current implementation
    username varchar,
    location text,
    created_posts post[],
    liked_posts post[],
    friends user[],
    notifications notification[],
}


Notification

Brew (type of drink abstraction)