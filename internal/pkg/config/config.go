package config

import (
	"fmt"

	env "github.com/caarlos0/env/v6"
)

//Config is the basic app config.
type Config struct {
	DatabaseConnection string     `json:"database_connection" env:"DB_CON"`
	Migrations         Migrations `json:"migrations"`
}

// Migrations is the config for Database migrations.
type Migrations struct {
	Enabled   bool   `json:"enabled" env:"DB_MIGRATIONS_ENABLED"`
	Directory string `json:"directory" env:"DB_MIGRATIONS_DIR"`
}

//LoadConfig returns a config struct.
func LoadConfig() (*Config, error) {
	cfg := Config{}

	err := env.Parse(&cfg)
	if err != nil {
		return nil, fmt.Errorf("could not parse environment variables %w", err)
	}
	if len(cfg.DatabaseConnection) == 0 {
		cfg.DatabaseConnection = "host=localhost port=54321 user=postgres password=postgres dbname=postgres sslmode=disable"
	}

	if len(cfg.Migrations.Directory) == 0 {
		cfg.Migrations.Directory = "./sql/migrations"
	}
	return &cfg, nil
}
