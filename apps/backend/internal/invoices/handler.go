package invoices

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
)

type InvoiceItem struct {
	Name  string  `json:"name"`
	Qty   int     `json:"qty"`
	Price float64 `json:"price"`
	Total float64 `json:"total"`
}

type Invoice struct {
	ID            uuid.UUID       `json:"id" db:"id"`
	SpaceID       uuid.UUID       `json:"space_id" db:"space_id"`
	InvoiceNumber string          `json:"invoice_number" db:"invoice_number"`
	ClientName    string          `json:"client_name" db:"client_name"`
	ClientEmail   *string         `json:"client_email,omitempty" db:"client_email"`
	ItemsRaw      []byte          `json:"-" db:"items"`
	Items         []InvoiceItem   `json:"items"`
	Subtotal      float64         `json:"subtotal" db:"subtotal"`
	Tax           float64         `json:"tax" db:"tax"`
	Total         float64         `json:"total" db:"total"`
	Status        string          `json:"status" db:"status"` // 'draft', 'sent', 'paid', 'overdue'
	DueDate       *string         `json:"due_date,omitempty" db:"due_date"`
	Notes         *string         `json:"notes,omitempty" db:"notes"`
	CreatedAt     time.Time       `json:"created_at" db:"created_at"`
	UpdatedAt     time.Time       `json:"updated_at" db:"updated_at"`
}

type CreateInvoiceRequest struct {
	ClientName  string        `json:"client_name"`
	ClientEmail *string       `json:"client_email"`
	Items       []InvoiceItem `json:"items"`
	Tax         float64       `json:"tax"`
	DueDate     *string       `json:"due_date"`
	Notes       *string       `json:"notes"`
}

type UpdateInvoiceStatusRequest struct {
	Status string `json:"status"` // 'draft', 'sent', 'paid', 'overdue'
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
		SELECT id, space_id, invoice_number, client_name, client_email, items, subtotal, tax, total, status,
		       to_char(due_date, 'YYYY-MM-DD') as due_date, notes, created_at, updated_at
		FROM invoices
		WHERE space_id = $1
		ORDER BY created_at DESC
	`

	var list []Invoice
	err = h.db.Select(&list, query, spaceID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"success": false, "message": "Failed to retrieve invoices"})
	}

	for i := range list {
		if len(list[i].ItemsRaw) > 0 {
			_ = json.Unmarshal(list[i].ItemsRaw, &list[i].Items)
		}
		if list[i].Items == nil {
			list[i].Items = []InvoiceItem{}
		}
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

	var req CreateInvoiceRequest
	if err := c.BodyParser(&req); err != nil || req.ClientName == "" || len(req.Items) == 0 {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"success": false, "message": "Client name and at least one item are required"})
	}

	subtotal := 0.0
	for i := range req.Items {
		req.Items[i].Total = float64(req.Items[i].Qty) * req.Items[i].Price
		subtotal += req.Items[i].Total
	}
	total := subtotal + req.Tax

	itemsJSON, err := json.Marshal(req.Items)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"success": false, "message": "Invalid items format"})
	}

	invoiceID := uuid.New()
	invoiceNumber := fmt.Sprintf("INV-%d-%s", time.Now().Unix(), invoiceID.String()[:4])
	now := time.Now()

	_, err = h.db.Exec(`
		INSERT INTO invoices (id, space_id, invoice_number, client_name, client_email, items, subtotal, tax, total, status, due_date, notes, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, 'draft', $10, $11, $12, $13)
	`, invoiceID, spaceID, invoiceNumber, req.ClientName, req.ClientEmail, itemsJSON, subtotal, req.Tax, total, req.DueDate, req.Notes, now, now)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"success": false, "message": "Failed to create invoice"})
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"success": true,
		"data": Invoice{
			ID:            invoiceID,
			SpaceID:       uuid.MustParse(spaceID),
			InvoiceNumber: invoiceNumber,
			ClientName:    req.ClientName,
			ClientEmail:   req.ClientEmail,
			Items:         req.Items,
			Subtotal:      subtotal,
			Tax:           req.Tax,
			Total:         total,
			Status:        "draft",
			DueDate:       req.DueDate,
			Notes:         req.Notes,
			CreatedAt:     now,
			UpdatedAt:     now,
		},
	})
}

func (h *Handler) UpdateStatus(c *fiber.Ctx) error {
	userID := c.Locals("userId").(string)
	invoiceID := c.Params("id")

	var req UpdateInvoiceStatusRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"success": false, "message": "Invalid status"})
	}

	res, err := h.db.Exec(`
		UPDATE invoices 
		SET status = $1, updated_at = now() 
		WHERE id = $2 AND space_id IN (SELECT id FROM spaces WHERE user_id = $3)
	`, req.Status, invoiceID, userID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"success": false, "message": "Failed to update invoice status"})
	}

	rows, _ := res.RowsAffected()
	if rows == 0 {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"success": false, "message": "Invoice not found"})
	}

	return c.JSON(fiber.Map{"success": true, "message": "Invoice status updated successfully"})
}
