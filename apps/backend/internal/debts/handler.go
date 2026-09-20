package debts

import (
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
)

type Debt struct {
	ID           uuid.UUID `json:"id" db:"id"`
	SpaceID      uuid.UUID `json:"space_id" db:"space_id"`
	Type         string    `json:"type" db:"type"` // 'payable' (utang kita) or 'receivable' (piutang org lain ke kita)
	Counterparty string    `json:"counterparty" db:"counterparty"`
	Amount       float64   `json:"amount" db:"amount"`
	DueDate      *string   `json:"due_date,omitempty" db:"due_date"`
	Notes        *string   `json:"notes,omitempty" db:"notes"`
	Status       string    `json:"status" db:"status"` // 'unpaid' or 'paid'
	CreatedAt    time.Time `json:"created_at" db:"created_at"`
	UpdatedAt    time.Time `json:"updated_at" db:"updated_at"`
}

type CreateDebtRequest struct {
	Type         string  `json:"type"` // 'payable' or 'receivable'
	Counterparty string  `json:"counterparty"`
	Amount       float64 `json:"amount"`
	DueDate      *string `json:"due_date"`
	Notes        *string `json:"notes"`
}

type UpdateDebtStatusRequest struct {
	Status string `json:"status"` // 'unpaid' or 'paid'
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
		SELECT id, space_id, type, counterparty, amount, to_char(due_date, 'YYYY-MM-DD') as due_date,
		       notes, status, created_at, updated_at
		FROM debts
		WHERE space_id = $1
		ORDER BY status ASC, due_date ASC NULLS LAST, created_at DESC
	`

	var list []Debt
	err = h.db.Select(&list, query, spaceID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"success": false, "message": "Failed to retrieve debts"})
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

	var req CreateDebtRequest
	if err := c.BodyParser(&req); err != nil || req.Counterparty == "" || req.Amount <= 0 {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"success": false, "message": "Counterparty and amount are required"})
	}
	if req.Type != "payable" && req.Type != "receivable" {
		req.Type = "receivable"
	}

	debtID := uuid.New()
	now := time.Now()

	_, err = h.db.Exec(`
		INSERT INTO debts (id, space_id, type, counterparty, amount, due_date, notes, status, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, 'unpaid', $8, $9)
	`, debtID, spaceID, req.Type, req.Counterparty, req.Amount, req.DueDate, req.Notes, now, now)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"success": false, "message": "Failed to record debt"})
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"success": true,
		"data": Debt{
			ID:           debtID,
			SpaceID:      uuid.MustParse(spaceID),
			Type:         req.Type,
			Counterparty: req.Counterparty,
			Amount:       req.Amount,
			DueDate:      req.DueDate,
			Notes:        req.Notes,
			Status:       "unpaid",
			CreatedAt:    now,
			UpdatedAt:    now,
		},
	})
}

func (h *Handler) UpdateStatus(c *fiber.Ctx) error {
	userID := c.Locals("userId").(string)
	debtID := c.Params("id")

	var req UpdateDebtStatusRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"success": false, "message": "Invalid status"})
	}

	res, err := h.db.Exec(`
		UPDATE debts 
		SET status = $1, updated_at = now() 
		WHERE id = $2 AND space_id IN (SELECT id FROM spaces WHERE user_id = $3)
	`, req.Status, debtID, userID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"success": false, "message": "Failed to update status"})
	}

	rows, _ := res.RowsAffected()
	if rows == 0 {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"success": false, "message": "Record not found"})
	}

	return c.JSON(fiber.Map{"success": true, "message": "Status updated successfully"})
}
