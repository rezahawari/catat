package transactions

import (
	"database/sql"
	"fmt"
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

func (h *Handler) List(c *fiber.Ctx) error {
	userID := c.Locals("userId").(string)
	spaceID := c.Params("spaceId")

	var count int
	err := h.db.Get(&count, "SELECT count(*) FROM spaces WHERE id = $1 AND user_id = $2", spaceID, userID)
	if err != nil || count == 0 {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"success": false, "message": "Access denied to space"})
	}

	from := c.Query("from")
	to := c.Query("to")
	category := c.Query("category")
	account := c.Query("account")

	query := `
		SELECT 
			t.id, t.space_id, t.account_id, a.name as account_name,
			t.category_id, c.name as category_name, c.icon as category_icon,
			t.amount, t.type, t.note, to_char(t.transaction_date, 'YYYY-MM-DD') as transaction_date,
			t.is_recurring, t.recurring_rule, t.sync_status, t.created_at, t.updated_at
		FROM transactions t
		LEFT JOIN accounts a ON t.account_id = a.id
		LEFT JOIN categories c ON t.category_id = c.id
		WHERE t.space_id = $1
	`
	args := []interface{}{spaceID}
	argIdx := 2

	if from != "" {
		query += fmt.Sprintf(" AND t.transaction_date >= $%d", argIdx)
		args = append(args, from)
		argIdx++
	}
	if to != "" {
		query += fmt.Sprintf(" AND t.transaction_date <= $%d", argIdx)
		args = append(args, to)
		argIdx++
	}
	if category != "" {
		query += fmt.Sprintf(" AND t.category_id = $%d", argIdx)
		args = append(args, category)
		argIdx++
	}
	if account != "" {
		query += fmt.Sprintf(" AND t.account_id = $%d", argIdx)
		args = append(args, account)
		argIdx++
	}

	query += " ORDER BY t.transaction_date DESC, t.created_at DESC"

	var list []Transaction
	err = h.db.Select(&list, query, args...)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"success": false, "message": "Failed to retrieve transactions"})
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

	var req CreateTransactionRequest
	if err := c.BodyParser(&req); err != nil || req.Amount <= 0 || req.TransactionDate == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"success": false, "message": "Valid amount and transaction date are required"})
	}

	if req.Type != "income" && req.Type != "expense" {
		req.Type = "expense"
	}

	tx, err := h.db.Beginx()
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"success": false, "message": "Database transaction error"})
	}
	defer tx.Rollback()

	txnID := uuid.New()
	if req.ID != nil && *req.ID != "" {
		if parsed, parseErr := uuid.Parse(*req.ID); parseErr == nil {
			txnID = parsed
		}
	}

	now := time.Now()
	_, err = tx.Exec(`
		INSERT INTO transactions (id, space_id, account_id, category_id, amount, type, note, transaction_date, is_recurring, recurring_rule, sync_status, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, 'synced', $11, $12)
	`, txnID, spaceID, req.AccountID, req.CategoryID, req.Amount, req.Type, req.Note, req.TransactionDate, req.IsRecurring, req.RecurringRule, now, now)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"success": false, "message": "Failed to save transaction"})
	}

	// Update account balance if account_id is provided
	if req.AccountID != nil && *req.AccountID != "" {
		delta := req.Amount
		if req.Type == "expense" {
			delta = -delta
		}
		_, _ = tx.Exec("UPDATE accounts SET balance = balance + $1 WHERE id = $2", delta, *req.AccountID)
	}

	if err := tx.Commit(); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"success": false, "message": "Failed to commit transaction"})
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"success": true,
		"data": Transaction{
			ID:              txnID,
			SpaceID:         uuid.MustParse(spaceID),
			Amount:          req.Amount,
			Type:            req.Type,
			Note:            req.Note,
			TransactionDate: req.TransactionDate,
			IsRecurring:     req.IsRecurring,
			RecurringRule:   req.RecurringRule,
			SyncStatus:      "synced",
			CreatedAt:       now,
			UpdatedAt:       now,
		},
	})
}

func (h *Handler) Summary(c *fiber.Ctx) error {
	userID := c.Locals("userId").(string)
	spaceID := c.Params("spaceId")

	var count int
	err := h.db.Get(&count, "SELECT count(*) FROM spaces WHERE id = $1 AND user_id = $2", spaceID, userID)
	if err != nil || count == 0 {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"success": false, "message": "Access denied to space"})
	}

	month := c.Query("month")
	year := c.Query("year")
	if month == "" || year == "" {
		now := time.Now()
		month = fmt.Sprintf("%02d", now.Month())
		year = fmt.Sprintf("%d", now.Year())
	}

	startDate := fmt.Sprintf("%s-%s-01", year, month)
	query := `
		SELECT 
			COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0) as total_income,
			COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0) as total_expense,
			COUNT(id) as transaction_count
		FROM transactions
		WHERE space_id = $1 
		  AND transaction_date >= $2::date 
		  AND transaction_date < ($2::date + INTERVAL '1 month')
	`
	var summary struct {
		TotalIncome      float64 `db:"total_income"`
		TotalExpense     float64 `db:"total_expense"`
		TransactionCount int     `db:"transaction_count"`
	}

	err = h.db.Get(&summary, query, spaceID, startDate)
	if err != nil && err != sql.ErrNoRows {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"success": false, "message": "Failed to calculate summary"})
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data": MonthlySummary{
			TotalIncome:      summary.TotalIncome,
			TotalExpense:     summary.TotalExpense,
			NetSavings:       summary.TotalIncome - summary.TotalExpense,
			TransactionCount: summary.TransactionCount,
		},
	})
}

func (h *Handler) BatchSync(c *fiber.Ctx) error {
	userID := c.Locals("userId").(string)
	spaceID := c.Params("spaceId")

	var count int
	err := h.db.Get(&count, "SELECT count(*) FROM spaces WHERE id = $1 AND user_id = $2", spaceID, userID)
	if err != nil || count == 0 {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"success": false, "message": "Access denied to space"})
	}

	var req SyncBatchRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"success": false, "message": "Invalid sync payload"})
	}

	tx, err := h.db.Beginx()
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"success": false, "message": "Transaction error"})
	}
	defer tx.Rollback()

	now := time.Now()
	syncedIDs := make([]string, 0)

	for _, item := range req.Transactions {
		var itemID uuid.UUID
		if item.ID != nil && *item.ID != "" {
			parsed, parseErr := uuid.Parse(*item.ID)
			if parseErr == nil {
				itemID = parsed
			} else {
				itemID = uuid.New()
			}
		} else {
			itemID = uuid.New()
		}

		_, err = tx.Exec(`
			INSERT INTO transactions (id, space_id, account_id, category_id, amount, type, note, transaction_date, is_recurring, recurring_rule, sync_status, created_at, updated_at)
			VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, 'synced', $11, $12)
			ON CONFLICT (id) DO UPDATE SET
				amount = EXCLUDED.amount,
				type = EXCLUDED.type,
				note = EXCLUDED.note,
				transaction_date = EXCLUDED.transaction_date,
				sync_status = 'synced',
				updated_at = EXCLUDED.updated_at
		`, itemID, spaceID, item.AccountID, item.CategoryID, item.Amount, item.Type, item.Note, item.TransactionDate, item.IsRecurring, item.RecurringRule, now, now)

		if err == nil {
			syncedIDs = append(syncedIDs, itemID.String())
		}
	}

	if err := tx.Commit(); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"success": false, "message": "Failed to commit sync"})
	}

	return c.JSON(fiber.Map{
		"success":    true,
		"synced_ids": syncedIDs,
	})
}
