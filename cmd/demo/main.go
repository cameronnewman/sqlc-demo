package main

import (
	"context"
	"database/sql"
	"log"
	"os"
	"time"

	"github.com/cameronnewman/sqlc-demo/internal/pkg/config"
	"github.com/cameronnewman/sqlc-demo/internal/pkg/migrator"
	"github.com/cameronnewman/sqlc-demo/internal/pkg/store"
	"github.com/google/uuid"
	"github.com/shopspring/decimal"

	_ "github.com/jackc/pgx/v4/stdlib"
	"go.uber.org/zap"
)

func main() {

	cfg, err := config.LoadConfig()
	if err != nil {
		log.Fatalf("Failed to create a config instance %v", err)
	}

	logConfig := zap.NewDevelopmentConfig()
	logger, err := logConfig.Build()
	if err != nil {
		log.Fatalf("can't initialize zap logger: %v", err)
	}
	defer check(logger.Sync)

	if logConfig.Development {
		logger.Info("Set logging to Development")
	}

	logger.Info("Creating sql instance")
	sql, err := createDatabaseConnection(cfg.DatabaseConnection)
	if err != nil {
		logger.Fatal("can't initialize sql database connection", zap.Error(err))
	}

	// :TODO: break this into separate service
	logger.Info("Running config SQL Migration")
	if err := migrator.Migration(migrator.Options{
		Enabled:   cfg.Migrations.Enabled,
		Directory: cfg.Migrations.Directory,
	}, sql, logger); err != nil {
		logger.Fatal("Migration failed", zap.Error(err))
	}

	ctx := context.Background()
	loanStore := store.New(sql)

	loan, err := loanStore.Create(ctx, store.CreateParams{
		LoanID:             uuid.Must(uuid.NewRandom()),
		ArtifactType:       store.ArtifactTypeInvoice,
		ArtifactID:         uuid.Must(uuid.NewRandom()),
		MerchantID:         uuid.Must(uuid.NewRandom()),
		PayeeID:            uuid.Must(uuid.NewRandom()),
		PayeeType:          store.PayeeTypeUser,
		NumberOfRepayments: 10,
		LoanAmount:         decimal.NewFromFloat(1000),
		MerchantFee:        decimal.NewFromFloat(100),
		Principal:          decimal.NewFromFloat(200),
		SetupFee:           decimal.NewFromFloat(300),
		TotalRepayable:     decimal.NewFromFloat(10000),
		Status:             store.LoanStatusApproved,
		NextRepaymentDate:  time.Now(),
		OriginationDate:    time.Now(),
		MaturationDate:     time.Now(),
	})

	if err != nil {
		logger.Fatal("Failed to create loan", zap.Error(err))
	}
	logger.Info("Created Loan", zap.String("loan_id", loan.LoanID.String()), zap.Any("loan", loan))
	os.Exit(0)
}

func check(f func() error) {
	if err := f(); err != nil {
		log.Println("Received error:", err)
	}
}

// CreateDatabaseConnection returns a SQL DB pointer
func createDatabaseConnection(connection string) (*sql.DB, error) {
	const (
		maxConnections int = 20

		// dbDriverPGX is the driver name for stdlib Postgres in github.com/jackc/pgx
		dbDriverPGX string = "pgx"
	)

	db, err := sql.Open(dbDriverPGX, connection)
	if err != nil {
		return nil, err
	}
	db.SetMaxOpenConns(maxConnections)

	err = db.Ping()
	if err != nil {
		return nil, err
	}

	return db, nil
}
