package budgets

import (
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
)

type Budget struct {
	ID           uuid.UUID `json:"id" db:"id"`
	SpaceID      uuid.UUID `json:"space_id" db:"space_id"`
	CategoryID   uuid.UUID `json:"category_id" db:"category_id"`
	CategoryName *string   `json:"category_name,omitempty" db:"category_name"`
	CategoryIcon *string   `json:"category_icon,omitempty" db:"category_icon"`
	Amount       float64   `json:"amount" db:"amount"`
	SpentAmount  float64   `json:"spent_amount" db:"spent_amount"`
	PeriodStart  string    `json:"period_start" db:"period_start"`
	PeriodEnd    string    `json:"period_end" db:"period_end"`
	CreatedAt    time.Time `json:"created_at" db:"created_at"`
}

type CreateBudgetRequest struct {
	CategoryID  string  `json:"category_id"`
	Amount      float64 `json:"amount"`
	PeriodStart string  `json:"period_start"`
	PeriodEnd   string  `json:"period_end"`
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
		SELECT 
			b.id, b.space_id, b.category_id, c.name as category_name, c.icon as category_icon,
			b.amount,
			COALESCE(
				(SELECT SUM(t.amount) 
				 FROM transactions t 
				 WHERE t.space_id = b.space_id 
				   AND t.category_id = b.category_id 
				   AND t.type = 'expense'
				   AND t.transaction_date >= b.period_start 
				   AND t.transaction_date <= b.period_end), 
			0) as spent_amount,
			to_char(b.period_start, 'YYYY-MM-DD') as period_start,
			to_char(b.period_end, 'YYYY-MM-DD') as period_end,
			b.created_at
		FROM budgets b
		LEFT JOIN categories c ON b.category_id = c.id
		WHERE b.space_id = $1
		ORDER BY b.created_at DESC
	`

	var list []Budget
	err = h.db.Select(&list, query, spaceID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"success": false, "message": "Failed to retrieve budgets"})
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

	var req CreateBudgetRequest
	if err := c.BodyParser(&req); err != nil || req.Amount <= 0 || req.CategoryID == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"success": false, "message": "Valid category and amount required"})
	}

	budgetID := uuid.New()
	now := time.Now()
	_, err = h.db.Exec(`
		INSERT INTO budgets (id, space_id, category_id, amount, period_start, period_end, created_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
	`, budgetID, spaceID, req.CategoryID, req.Amount, req.PeriodStart, req.PeriodEnd, now)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"success": false, "message": "Failed to create budget"})
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"success": true,
		"data": fiber.Map{
			"id":           budgetID,
			"space_id":     spaceID,
			"category_id":  req.CategoryID,
			"amount":       req.Amount,
			"period_start": req.PeriodStart,
			"period_end":   req.PeriodEnd,
		},
	})
}

func (h *Handler) Delete(c *fiber.Ctx) error {
	userID := c.Locals("userId").(string)
	budgetID := c.Params("id")

	res, err := h.db.Exec(`
		DELETE FROM budgets 
		WHERE id = $1 AND space_id IN (SELECT id FROM spaces WHERE user_id = $2)
	`, budgetID, userID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"success": false, "message": "Failed to delete budget"})
	}

	rows, _ := res.RowsAffected()
	if rows == 0 {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"success": false, "message": "Budget not found"})
	}

	return c.JSON(fiber.Map{"success": true, "message": "Budget deleted successfully"})
}
