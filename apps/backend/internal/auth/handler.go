package auth

import (
	"database/sql"
	"time"

	"github.com/finflow/backend/internal/config"
	"github.com/finflow/backend/internal/middleware"
	"github.com/gofiber/fiber/v2"
	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
	"golang.org/x/crypto/bcrypt"
)

type Handler struct {
	db  *sqlx.DB
	cfg *config.Config
}

func NewHandler(db *sqlx.DB, cfg *config.Config) *Handler {
	return &Handler{db: db, cfg: cfg}
}

func (h *Handler) Register(c *fiber.Ctx) error {
	var req RegisterRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"success": false, "message": "Invalid request body"})
	}

	if req.Email == "" || req.Password == "" || req.Name == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"success": false, "message": "Name, email, and password are required"})
	}

	// Check if user already exists
	var existingID uuid.UUID
	err := h.db.Get(&existingID, "SELECT id FROM users WHERE email = $1", req.Email)
	if err == nil {
		return c.Status(fiber.StatusConflict).JSON(fiber.Map{"success": false, "message": "Email is already registered"})
	}

	// Hash password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"success": false, "message": "Failed to hash password"})
	}

	tx, err := h.db.Beginx()
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"success": false, "message": "Database transaction error"})
	}
	defer tx.Rollback()

	userID := uuid.New()
	now := time.Now()
	_, err = tx.Exec(
		`INSERT INTO users (id, email, password_hash, name, created_at, updated_at) VALUES ($1, $2, $3, $4, $5, $6)`,
		userID, req.Email, string(hashedPassword), req.Name, now, now,
	)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"success": false, "message": "Failed to create user"})
	}

	// Auto create default "Personal Space"
	spaceID := uuid.New()
	_, err = tx.Exec(
		`INSERT INTO spaces (id, user_id, type, name, created_at) VALUES ($1, $2, 'personal', 'Keuangan Pribadi', $3)`,
		spaceID, userID, now,
	)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"success": false, "message": "Failed to create default space"})
	}

	// Auto create default Accounts
	defaultAccounts := []struct {
		Name    string
		Type    string
		Balance float64
	}{
		{"Uang Tunai (Cash)", "cash", 0},
		{"Rekening Bank (BCA/Mandiri)", "bank", 0},
		{"E-Wallet (GoPay/OVO/Dana)", "ewallet", 0},
	}
	for _, acc := range defaultAccounts {
		accID := uuid.New()
		_, _ = tx.Exec(
			`INSERT INTO accounts (id, space_id, name, type, balance, currency, created_at) VALUES ($1, $2, $3, $4, $5, 'IDR', $6)`,
			accID, spaceID, acc.Name, acc.Type, acc.Balance, now,
		)
	}

	// Auto create default Categories
	defaultCategories := []struct {
		Name string
		Type string
		Icon string
	}{
		{"Gaji Bulanan", "income", "wallet"},
		{"Freelance & Side Job", "income", "briefcase"},
		{"Investasi / Bunga", "income", "trending-up"},
		{"Lainnya (Pemasukan)", "income", "plus-circle"},
		{"Makanan & Minuman", "expense", "coffee"},
		{"Transportasi & Bensin", "expense", "navigation"},
		{"Belanja & Kebutuhan", "expense", "shopping-bag"},
		{"Tagihan & Listrik/Air", "expense", "file-text"},
		{"Hiburan & Langganan", "expense", "film"},
		{"Kesehatan & Medis", "expense", "activity"},
		{"Lainnya (Pengeluaran)", "expense", "more-horizontal"},
	}
	for _, cat := range defaultCategories {
		catID := uuid.New()
		_, _ = tx.Exec(
			`INSERT INTO categories (id, space_id, name, type, icon, is_default) VALUES ($1, $2, $3, $4, $5, true)`,
			catID, spaceID, cat.Name, cat.Type, cat.Icon,
		)
	}

	if err := tx.Commit(); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"success": false, "message": "Failed to finalize registration"})
	}

	user := User{
		ID:        userID,
		Email:     req.Email,
		Name:      req.Name,
		CreatedAt: now,
		UpdatedAt: now,
	}

	accessToken, refreshToken, err := h.generateTokens(user.ID.String(), user.Email)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"success": false, "message": "Failed to generate tokens"})
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"success": true,
		"data": AuthResponse{
			User:         user,
			AccessToken:  accessToken,
			RefreshToken: refreshToken,
		},
	})
}

func (h *Handler) Login(c *fiber.Ctx) error {
	var req LoginRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"success": false, "message": "Invalid request body"})
	}

	var user User
	err := h.db.Get(&user, "SELECT id, email, password_hash, name, google_id, created_at, updated_at FROM users WHERE email = $1", req.Email)
	if err != nil {
		if err == sql.ErrNoRows {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"success": false, "message": "Email or password incorrect"})
		}
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"success": false, "message": "Database query error"})
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)); err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"success": false, "message": "Email or password incorrect"})
	}

	accessToken, refreshToken, err := h.generateTokens(user.ID.String(), user.Email)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"success": false, "message": "Failed to generate tokens"})
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data": AuthResponse{
			User:         user,
			AccessToken:  accessToken,
			RefreshToken: refreshToken,
		},
	})
}

func (h *Handler) RefreshToken(c *fiber.Ctx) error {
	var req RefreshTokenRequest
	if err := c.BodyParser(&req); err != nil || req.RefreshToken == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"success": false, "message": "Refresh token required"})
	}

	claims := &middleware.JWTClaims{}
	token, err := jwt.ParseWithClaims(req.RefreshToken, claims, func(token *jwt.Token) (interface{}, error) {
		return []byte(h.cfg.JWTRefreshSecret), nil
	})

	if err != nil || !token.Valid {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"success": false, "message": "Invalid or expired refresh token"})
	}

	var user User
	err = h.db.Get(&user, "SELECT id, email, name, created_at, updated_at FROM users WHERE id = $1", claims.UserID)
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"success": false, "message": "User not found"})
	}

	accessToken, newRefreshToken, err := h.generateTokens(user.ID.String(), user.Email)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"success": false, "message": "Failed to refresh tokens"})
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data": fiber.Map{
			"access_token":  accessToken,
			"refresh_token": newRefreshToken,
		},
	})
}

func (h *Handler) GetMe(c *fiber.Ctx) error {
	userID := c.Locals("userId").(string)
	var user User
	err := h.db.Get(&user, "SELECT id, email, name, google_id, created_at, updated_at FROM users WHERE id = $1", userID)
	if err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"success": false, "message": "User not found"})
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data":    user,
	})
}

func (h *Handler) generateTokens(userID, email string) (string, string, error) {
	// Access token (15 mins)
	accessClaims := &middleware.JWTClaims{
		UserID: userID,
		Email:  email,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(15 * time.Minute)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}
	accessTokenObj := jwt.NewWithClaims(jwt.SigningMethodHS256, accessClaims)
	accessToken, err := accessTokenObj.SignedString([]byte(h.cfg.JWTAccessSecret))
	if err != nil {
		return "", "", err
	}

	// Refresh token (30 days)
	refreshClaims := &middleware.JWTClaims{
		UserID: userID,
		Email:  email,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(30 * 24 * time.Hour)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}
	refreshTokenObj := jwt.NewWithClaims(jwt.SigningMethodHS256, refreshClaims)
	refreshToken, err := refreshTokenObj.SignedString([]byte(h.cfg.JWTRefreshSecret))
	if err != nil {
		return "", "", err
	}

	return accessToken, refreshToken, nil
}
