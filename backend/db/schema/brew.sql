-- Brew table
-- Represents a type of coffee or specific brew configuration
CREATE TABLE brew (
    id TEXT PRIMARY KEY, -- ULID format
    name VARCHAR(255) NOT NULL,
    brew_method VARCHAR(100),
    bean_origin TEXT,
    roaster TEXT,
    notes TEXT,
    created_by TEXT REFERENCES "user"(id),
    is_public BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for common queries
CREATE INDEX idx_brew_created_by ON brew(created_by);
CREATE INDEX idx_brew_is_public ON brew(is_public);
CREATE INDEX idx_brew_name ON brew(name);
CREATE INDEX idx_brew_method ON brew(brew_method);
