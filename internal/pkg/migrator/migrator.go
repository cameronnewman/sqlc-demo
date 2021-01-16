package migrator

import (
	"database/sql"
	"time"

	_ "github.com/jackc/pgx/v4/stdlib"
	migrate "github.com/rubenv/sql-migrate"
	"go.uber.org/zap"
)

// Options for Migration
type Options struct {
	Enabled   bool
	Directory string
}

//Migration runs the SQL migration.
func Migration(options Options, sql *sql.DB, logger *zap.Logger) error {
	const (
		migrateSchema string = "app"
		migrateTable  string = "_schema_history"

		dbDriverPG string = "postgres"
	)

	logger.Info("Bootstrapping: Migrations")

	if !options.Enabled {
		logger.Info("Migration disabled")
		return nil
	}

	err := sql.Ping()
	if err != nil {
		logger.Debug("Failed to connect to database", zap.Error(err))
		return err
	}

	migrations := &migrate.FileMigrationSource{
		Dir: options.Directory,
	}

	source, err := migrations.FindMigrations()
	if err != nil {
		logger.Debug("Failed to find any Migrations", zap.Error(err))
		return err
	}

	migrate.SetSchema(migrateSchema)
	migrate.SetTable(migrateTable)
	n, err := migrate.Exec(sql, dbDriverPG, migrations, migrate.Up)
	if err != nil {
		logger.Debug("Failed to run Migrations", zap.Error(err))
		return err
	}

	if n == 0 {
		logger.Debug("No migrations to apply")
	} else {
		logger.Debug("Completed migrations", zap.Int("applied", n))
	}

	applied, err := migrate.GetMigrationRecords(sql, dbDriverPG)
	if err != nil {
		return err
	}

	appliedMap := make(map[string]time.Time)
	for _, m := range applied {
		appliedMap[m.Id] = m.AppliedAt
	}

	for _, m := range source {
		_, ok := appliedMap[m.Id]
		if ok {
			logger.Debug("", zap.String("id", m.Id), zap.Bool("applied", true), zap.String("applied_at", appliedMap[m.Id].String()))
		} else {
			logger.Debug("", zap.String("id", m.Id), zap.Bool("applied", false), zap.String("applied_at", ""))
		}
	}

	return nil
}
