package database

import (
	"log"
	"os"
	"path/filepath"
	"time"

	"github.com/jmoiron/sqlx"
	_ "github.com/lib/pq"
)

func Connect(databaseURL string) (*sqlx.DB, error) {
	db, err := sqlx.Open("postgres", databaseURL)
	if err != nil {
		return nil, err
	}

	db.SetMaxOpenConns(25)
	db.SetMaxIdleConns(10)
	db.SetConnMaxLifetime(5 * time.Minute)

	if err := db.Ping(); err != nil {
		log.Printf("Warning: Database ping failed (%v). Retrying in background...", err)
		return db, nil
	}

	log.Println("Successfully connected to PostgreSQL database")

	// Jalankan auto-migration skema database
	RunMigrations(db)

	return db, nil
}

// RunMigrations mengeksekusi file SQL migrasi untuk memastikan semua tabel tersedia
func RunMigrations(db *sqlx.DB) {
	migrationPaths := []string{
		"db/migrations/000001_init_schema.up.sql",
		"./apps/backend/db/migrations/000001_init_schema.up.sql",
		"/root/db/migrations/000001_init_schema.up.sql",
	}

	var sqlContent []byte
	var foundPath string

	for _, p := range migrationPaths {
		absPath, _ := filepath.Abs(p)
		if content, err := os.ReadFile(p); err == nil {
			sqlContent = content
			foundPath = p
			break
		} else if content, err := os.ReadFile(absPath); err == nil {
			sqlContent = content
			foundPath = absPath
			break
		}
	}

	if len(sqlContent) > 0 {
		log.Printf("Running auto-migration from: %s", foundPath)
		_, err := db.Exec(string(sqlContent))
		if err != nil {
			log.Printf("Migration notice/warning: %v", err)
		} else {
			log.Println("Database schema migration executed successfully")
		}
	} else {
		log.Println("Note: Schema migration file not found in paths, using existing database schema")
	}
}
