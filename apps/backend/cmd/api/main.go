package main

import (
	"log"

	"github.com/finflow/backend/internal/accounts"
	"github.com/finflow/backend/internal/auth"
	"github.com/finflow/backend/internal/budgets"
	"github.com/finflow/backend/internal/categories"
	"github.com/finflow/backend/internal/config"
	"github.com/finflow/backend/internal/database"
	"github.com/finflow/backend/internal/debts"
	"github.com/finflow/backend/internal/goals"
	"github.com/finflow/backend/internal/invoices"
	"github.com/finflow/backend/internal/middleware"
	"github.com/finflow/backend/internal/reports"
	"github.com/finflow/backend/internal/spaces"
	"github.com/finflow/backend/internal/transactions"
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/logger"
	"github.com/gofiber/fiber/v2/middleware/recover"
)

func main() {
	cfg := config.Load()

	db, err := database.Connect(cfg.DatabaseURL)
	if err != nil {
		log.Fatalf("Failed to initialize database: %v", err)
	}
	defer db.Close()

	app := fiber.New(fiber.Config{
		AppName:      "Catat Backend API v1.0",
		ServerHeader: "Fiber",
	})

	app.Use(recover.New())
	app.Use(logger.New(logger.Config{
		Format: "[${time}] ${status} - ${latency} ${method} ${path}\n",
	}))
	app.Use(cors.New(cors.Config{
		AllowOrigins: "*",
		AllowHeaders: "Origin, Content-Type, Accept, Authorization",
		AllowMethods: "GET, POST, HEAD, PUT, DELETE, PATCH, OPTIONS",
	}))

	// Health Check with Database Connectivity Test
	app.Get("/health", func(c *fiber.Ctx) error {
		dbStatus := "connected"
		if err := db.Ping(); err != nil {
			dbStatus = "disconnected: " + err.Error()
		}

		return c.JSON(fiber.Map{
			"status":   "healthy",
			"service":  "catat-api",
			"database": dbStatus,
			"env":      cfg.Env,
		})
	})

	// Handlers
	authHandler := auth.NewHandler(db, cfg)
	spacesHandler := spaces.NewHandler(db)
	accountsHandler := accounts.NewHandler(db)
	categoriesHandler := categories.NewHandler(db)
	transactionsHandler := transactions.NewHandler(db)
	budgetsHandler := budgets.NewHandler(db)
	goalsHandler := goals.NewHandler(db)
	invoicesHandler := invoices.NewHandler(db)
	debtsHandler := debts.NewHandler(db)
	reportsHandler := reports.NewHandler(db)

	// Public Auth Routes
	authGroup := app.Group("/auth")
	authGroup.Post("/register", authHandler.Register)
	authGroup.Post("/login", authHandler.Login)
	authGroup.Post("/refresh", authHandler.RefreshToken)

	// Protected Routes (Require JWT)
	protected := app.Group("/", middleware.AuthRequired(cfg))

	// User Profile
	protected.Get("/auth/me", authHandler.GetMe)

	// Spaces
	protected.Get("/spaces", spacesHandler.ListSpaces)
	protected.Post("/spaces", spacesHandler.CreateSpace)
	protected.Get("/spaces/:id", spacesHandler.GetSpace)
	protected.Patch("/spaces/:id", spacesHandler.UpdateSpace)
	protected.Delete("/spaces/:id", spacesHandler.DeleteSpace)

	// Accounts
	protected.Get("/spaces/:spaceId/accounts", accountsHandler.ListBySpace)
	protected.Post("/spaces/:spaceId/accounts", accountsHandler.Create)
	protected.Patch("/accounts/:id", accountsHandler.Update)
	protected.Delete("/accounts/:id", accountsHandler.Delete)

	// Categories
	protected.Get("/spaces/:spaceId/categories", categoriesHandler.ListBySpace)
	protected.Post("/spaces/:spaceId/categories", categoriesHandler.Create)
	protected.Patch("/categories/:id", categoriesHandler.Update)
	protected.Delete("/categories/:id", categoriesHandler.Delete)

	// Transactions
	protected.Get("/spaces/:spaceId/transactions", transactionsHandler.List)
	protected.Post("/spaces/:spaceId/transactions", transactionsHandler.Create)
	protected.Get("/spaces/:spaceId/transactions/summary", transactionsHandler.Summary)
	protected.Post("/spaces/:spaceId/transactions/sync", transactionsHandler.BatchSync)

	// Budgets
	protected.Get("/spaces/:spaceId/budgets", budgetsHandler.ListBySpace)
	protected.Post("/spaces/:spaceId/budgets", budgetsHandler.Create)
	protected.Delete("/budgets/:id", budgetsHandler.Delete)

	// Goals
	protected.Get("/spaces/:spaceId/goals", goalsHandler.ListBySpace)
	protected.Post("/spaces/:spaceId/goals", goalsHandler.Create)
	protected.Patch("/goals/:id", goalsHandler.UpdateProgress)
	protected.Delete("/goals/:id", goalsHandler.Delete)

	// Invoices (Ruang Bisnis)
	protected.Get("/spaces/:spaceId/invoices", invoicesHandler.ListBySpace)
	protected.Post("/spaces/:spaceId/invoices", invoicesHandler.Create)
	protected.Patch("/invoices/:id/status", invoicesHandler.UpdateStatus)

	// Debts (Utang-Piutang)
	protected.Get("/spaces/:spaceId/debts", debtsHandler.ListBySpace)
	protected.Post("/spaces/:spaceId/debts", debtsHandler.Create)
	protected.Patch("/debts/:id/status", debtsHandler.UpdateStatus)

	// Reports
	protected.Get("/spaces/:spaceId/reports/profit-loss", reportsHandler.GetProfitLoss)
	protected.Get("/spaces/:spaceId/reports/cashflow-projection", reportsHandler.GetCashflowProjection)

	log.Printf("Catat Go API server listening on :%s\n", cfg.Port)
	if err := app.Listen(":" + cfg.Port); err != nil {
		log.Fatalf("Server startup failed: %v", err)
	}
}
