package accounts

import (
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
)

type Handler struct {
	db *sqlx.DB
}

func NewHandler(db *sqlx.DB) *Handler {
	return &Handler{db: db}
}

func (h *Handler) ListBySpace(c *fiber.Ctx) error {
	userID := c.Locals("userId").(string)
	spaceID := c.Params("spaceId")

	// Verify user owns the space
	var count int
	err := h.db.Get(&count, "SELECT count(*) FROM spaces WHERE id = $1 AND user_id = $2", spaceID, userID)
	if err != nil || count == 0 {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"success": false, "message": "Access denied to space"})
	}

	var list []Account
	err = h.db.Select(&list, "SELECT id, space_id, name, type, balance, currency, created_at FROM accounts WHERE space_id = $1 ORDER BY created_at ASC", spaceID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"success": false, "message": "Failed to retrieve accounts"})
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data":    list,
	})
}

func (h *Handler) Create(c *fiber.Ctx) error {
	userID := c.Locals("userId").(string)
	spaceID := c.Params("spaceId")

	var count int
	err := h.db.Get(&count, "SELECT count(*) FROM spaces WHERE id = $1 AND user_id = $2", spaceID, userID)
	if err != nil || count == 0 {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"success": false, "message": "Access denied to space"})
	}

	var req CreateAccountRequest
	if err := c.BodyParser(&req); err != nil || req.Name == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"success": false, "message": "Account name is required"})
	}

	if req.Type != "cash" && req.Type != "bank" && req.Type != "ewallet" {
		req.Type = "cash"
	}
	if req.Currency == "" {
		req.Currency = "IDR"
	}

	accID := uuid.New()
	now := time.Now()
	_, err = h.db.Exec(
		"INSERT INTO accounts (id, space_id, name, type, balance, currency, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7)",
		accID, spaceID, req.Name, req.Type, req.Balance, req.Currency, now,
	)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"success": false, "message": "Failed to create account"})
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"success": true,
		"data": Account{
			ID:        accID,
			SpaceID:   uuid.MustParse(spaceID),
			Name:      req.Name,
			Type:      req.Type,
			Balance:   req.Balance,
			Currency:  req.Currency,
			CreatedAt: now,
		},
	})
}

func (h *Handler) Update(c *fiber.Ctx) error {
	userID := c.Locals("userId").(string)
	accID := c.Params("id")

	var req UpdateAccountRequest
	if err := c.BodyParser(&req); err != nil || req.Name == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"success": false, "message": "Account name is required"})
	}

	// Verify account belongs to a space owned by user
	res, err := h.db.Exec(`
		UPDATE accounts 
		SET name = $1, balance = $2 
		WHERE id = $3 AND space_id IN (SELECT id FROM spaces WHERE user_id = $4)
	`, req.Name, req.Balance, accID, userID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"success": false, "message": "Failed to update account"})
	}

	rows, _ := res.RowsAffected()
	if rows == 0 {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"success": false, "message": "Account not found"})
	}

	return c.JSON(fiber.Map{"success": true, "message": "Account updated successfully"})
}

func (h *Handler) Delete(c *fiber.Ctx) error {
	userID := c.Locals("userId").(string)
	accID := c.Params("id")

	res, err := h.db.Exec(`
		DELETE FROM accounts 
		WHERE id = $1 AND space_id IN (SELECT id FROM spaces WHERE user_id = $2)
	`, accID, userID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"success": false, "message": "Failed to delete account"})
	}

	rows, _ := res.RowsAffected()
	if rows == 0 {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"success": false, "message": "Account not found"})
	}

	return c.JSON(fiber.Map{"success": true, "message": "Account deleted successfully"})
}
