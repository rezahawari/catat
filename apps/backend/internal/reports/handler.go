package reports

import (
	"database/sql"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/jmoiron/sqlx"
)

type ProfitLossReport struct {
	TotalRevenue      float64                 `json:"total_revenue"`
	TotalExpense      float64                 `json:"total_expense"`
	NetProfit         float64                 `json:"net_profit"`
	ProfitMarginPct   float64                 `json:"profit_margin_pct"`
	RevenueCategories []CategoryReportItem    `json:"revenue_categories"`
	ExpenseCategories []CategoryReportItem    `json:"expense_categories"`
}

type CategoryReportItem struct {
	CategoryID   string  `json:"category_id"`
	CategoryName string  `json:"category_name"`
	CategoryIcon string  `json:"category_icon"`
	Amount       float64 `json:"amount"`
	Percentage   float64 `json:"percentage"`
}

type CashflowProjection struct {
	CurrentCash         float64 `json:"current_cash"`
	PendingReceivables  float64 `json:"pending_receivables"`
	PendingPayables     float64 `json:"pending_payables"`
	ProjectedNetCash    float64 `json:"projected_net_cash"`
}

type Handler struct {
	db *sqlx.DB
}

func NewHandler(db *sqlx.DB) *Handler {
	return &Handler{db: db}
}

func (h *Handler) GetProfitLoss(c *fiber.Ctx) error {
	userID := c.Locals("userId").(string)
	spaceID := c.Params("spaceId")

	var count int
	err := h.db.Get(&count, "SELECT count(*) FROM spaces WHERE id = $1 AND user_id = $2", spaceID, userID)
	if err != nil || count == 0 {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"success": false, "message": "Access denied to space"})
	}

	from := c.Query("from")
	to := c.Query("to")

	if from == "" || to == "" {
		now := time.Now()
		from = time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, time.UTC).Format("2006-01-02")
		to = time.Date(now.Year(), now.Month()+1, 0, 23, 59, 59, 0, time.UTC).Format("2006-01-02")
	}

	// 1. Total revenue and expenses
	var totals struct {
		Revenue float64 `db:"revenue"`
		Expense float64 `db:"expense"`
	}
	err = h.db.Get(&totals, `
		SELECT 
			COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0) as revenue,
			COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0) as expense
		FROM transactions
		WHERE space_id = $1 AND transaction_date >= $2 AND transaction_date <= $3
	`, spaceID, from, to)
	if err != nil && err != sql.ErrNoRows {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"success": false, "message": "Failed to calculate totals"})
	}

	// 2. Category breakdowns
	type CatRow struct {
		CategoryID   string  `db:"category_id"`
		CategoryName string  `db:"category_name"`
		CategoryIcon string  `db:"category_icon"`
		Type         string  `db:"type"`
		Amount       float64 `db:"amount"`
	}

	var catRows []CatRow
	_ = h.db.Select(&catRows, `
		SELECT 
			c.id::text as category_id,
			c.name as category_name,
			COALESCE(c.icon, 'circle') as category_icon,
			t.type,
			SUM(t.amount) as amount
		FROM transactions t
		JOIN categories c ON t.category_id = c.id
		WHERE t.space_id = $1 AND t.transaction_date >= $2 AND t.transaction_date <= $3
		GROUP BY c.id, c.name, c.icon, t.type
		ORDER BY amount DESC
	`, spaceID, from, to)

	revenueCats := []CategoryReportItem{}
	expenseCats := []CategoryReportItem{}

	for _, row := range catRows {
		item := CategoryReportItem{
			CategoryID:   row.CategoryID,
			CategoryName: row.CategoryName,
			CategoryIcon: row.CategoryIcon,
			Amount:       row.Amount,
		}
		if row.Type == "income" {
			if totals.Revenue > 0 {
				item.Percentage = (row.Amount / totals.Revenue) * 100
			}
			revenueCats = append(revenueCats, item)
		} else {
			if totals.Expense > 0 {
				item.Percentage = (row.Amount / totals.Expense) * 100
			}
			expenseCats = append(expenseCats, item)
		}
	}

	netProfit := totals.Revenue - totals.Expense
	profitMargin := 0.0
	if totals.Revenue > 0 {
		profitMargin = (netProfit / totals.Revenue) * 100
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data": ProfitLossReport{
			TotalRevenue:      totals.Revenue,
			TotalExpense:      totals.Expense,
			NetProfit:         netProfit,
			ProfitMarginPct:   profitMargin,
			RevenueCategories: revenueCats,
			ExpenseCategories: expenseCats,
		},
	})
}

func (h *Handler) GetCashflowProjection(c *fiber.Ctx) error {
	userID := c.Locals("userId").(string)
	spaceID := c.Params("spaceId")

	var count int
	err := h.db.Get(&count, "SELECT count(*) FROM spaces WHERE id = $1 AND user_id = $2", spaceID, userID)
	if err != nil || count == 0 {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"success": false, "message": "Access denied to space"})
	}

	// 1. Current cash from accounts
	var currentCash float64
	_ = h.db.Get(&currentCash, "SELECT COALESCE(SUM(balance), 0) FROM accounts WHERE space_id = $1", spaceID)

	// 2. Pending receivables
	var pendingReceivables float64
	_ = h.db.Get(&pendingReceivables, "SELECT COALESCE(SUM(amount), 0) FROM debts WHERE space_id = $1 AND type = 'receivable' AND status = 'unpaid'", spaceID)

	// 3. Pending payables
	var pendingPayables float64
	_ = h.db.Get(&pendingPayables, "SELECT COALESCE(SUM(amount), 0) FROM debts WHERE space_id = $1 AND type = 'payable' AND status = 'unpaid'", spaceID)

	projectedCash := currentCash + pendingReceivables - pendingPayables

	return c.JSON(fiber.Map{
		"success": true,
		"data": CashflowProjection{
			CurrentCash:        currentCash,
			PendingReceivables: pendingReceivables,
			PendingPayables:    pendingPayables,
			ProjectedNetCash:   projectedCash,
		},
	})
}
