package config

import (
	"os"
)

type Config struct {
	Port              string
	Env               string
	DatabaseURL       string
	JWTAccessSecret   string
	JWTRefreshSecret  string
	GoogleClientID    string
	GoogleClientSecret string
}

func Load() *Config {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	env := os.Getenv("ENV")
	if env == "" {
		env = "development"
	}

	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		dbURL = "postgres://catat_user:catat_password@localhost:5432/catat_db?sslmode=disable"
	}

	jwtAccessSecret := os.Getenv("JWT_ACCESS_SECRET")
	if jwtAccessSecret == "" {
		jwtAccessSecret = "catat_jwt_access_super_secret_key_2026"
	}

	jwtRefreshSecret := os.Getenv("JWT_REFRESH_SECRET")
	if jwtRefreshSecret == "" {
		jwtRefreshSecret = "catat_jwt_refresh_super_secret_key_2026"
	}

	return &Config{
		Port:              port,
		Env:               env,
		DatabaseURL:       dbURL,
		JWTAccessSecret:   jwtAccessSecret,
		JWTRefreshSecret:  jwtRefreshSecret,
		GoogleClientID:    os.Getenv("GOOGLE_CLIENT_ID"),
		GoogleClientSecret: os.Getenv("GOOGLE_CLIENT_SECRET"),
	}
}
