package goals

import (
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
)

type Goal struct {
	ID            uuid.UUID `json:"id" db:"id"`
	SpaceID       uuid.UUID `json:"space_id" db:"space_id"`
	Name          string    `json:"name" db:"name"`
	TargetAmount  float64   `json:"target_amount" db:"target_amount"`
	CurrentAmount float64   `json:"current_amount" db:"current_amount"`
	Deadline      *string   `json:"deadline,omitempty" db:"deadline"`
	CreatedAt     time.Time `json:"created_at" db:"created_at"`
}

type CreateGoalRequest struct {
	Name          string  `json:"name"`
	TargetAmount  float64 `json:"target_amount"`
	CurrentAmount float64 `json:"current_amount"`
	Deadline      *string `json:"deadline"`
}

type UpdateGoalProgressRequest struct {
	CurrentAmount float64 `json:"current_amount"`
}

type Handler struct {
	db *sqlx.DB
}

func NewHandler(db *sqlx.DB) *Handler {
	return &Handler{db: db}
}

func (h *Handler) ListBySpace(c *fiber.Ctx) error {
	userID := c.Locals("userId").(string)
	spaceID := c.Params("spaceId")

	var count int
	err := h.db.Get(&count, "SELECT count(*) FROM spaces WHERE id = $1 AND user_id = $2", spaceID, userID)
	if err != nil || count == 0 {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"success": false, "message": "Access denied to space"})
	}

	query := `
		SELECT id, space_id, name, target_amount, current_amount, 
		       to_char(deadline, 'YYYY-MM-DD') as deadline, created_at
		FROM goals
		WHERE space_id = $1
		ORDER BY created_at DESC
	`

	var list []Goal
	err = h.db.Select(&list, query, spaceID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"success": false, "message": "Failed to retrieve goals"})
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

	var req CreateGoalRequest
	if err := c.BodyParser(&req); err != nil || req.Name == "" || req.TargetAmount <= 0 {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"success": false, "message": "Name and target amount required"})
	}

	goalID := uuid.New()
	now := time.Now()
	_, err = h.db.Exec(`
		INSERT INTO goals (id, space_id, name, target_amount, current_amount, deadline, created_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
	`, goalID, spaceID, req.Name, req.TargetAmount, req.CurrentAmount, req.Deadline, now)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"success": false, "message": "Failed to create savings goal"})
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"success": true,
		"data": Goal{
			ID:            goalID,
			SpaceID:       uuid.MustParse(spaceID),
			Name:          req.Name,
			TargetAmount:  req.TargetAmount,
			CurrentAmount: req.CurrentAmount,
			Deadline:      req.Deadline,
			CreatedAt:     now,
		},
	})
}

func (h *Handler) UpdateProgress(c *fiber.Ctx) error {
	userID := c.Locals("userId").(string)
	goalID := c.Params("id")

	var req UpdateGoalProgressRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"success": false, "message": "Invalid amount"})
	}

	res, err := h.db.Exec(`
		UPDATE goals 
		SET current_amount = $1 
		WHERE id = $2 AND space_id IN (SELECT id FROM spaces WHERE user_id = $3)
	`, req.CurrentAmount, goalID, userID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"success": false, "message": "Failed to update goal"})
	}

	rows, _ := res.RowsAffected()
	if rows == 0 {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"success": false, "message": "Goal not found"})
	}

	return c.JSON(fiber.Map{"success": true, "message": "Goal progress updated successfully"})
}

func (h *Handler) Delete(c *fiber.Ctx) error {
	userID := c.Locals("userId").(string)
	goalID := c.Params("id")

	res, err := h.db.Exec(`
		DELETE FROM goals 
		WHERE id = $1 AND space_id IN (SELECT id FROM spaces WHERE user_id = $2)
	`, goalID, userID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"success": false, "message": "Failed to delete goal"})
	}

	rows, _ := res.RowsAffected()
	if rows == 0 {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"success": false, "message": "Goal not found"})
	}

	return c.JSON(fiber.Map{"success": true, "message": "Goal deleted successfully"})
}
