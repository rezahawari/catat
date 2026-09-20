package transactions

import (
	"time"

	"github.com/google/uuid"
)

type Transaction struct {
	ID              uuid.UUID  `json:"id" db:"id"`
	SpaceID         uuid.UUID  `json:"space_id" db:"space_id"`
	AccountID       *uuid.UUID `json:"account_id" db:"account_id"`
	AccountName     *string    `json:"account_name,omitempty" db:"account_name"`
	CategoryID      *uuid.UUID `json:"category_id" db:"category_id"`
	CategoryName    *string    `json:"category_name,omitempty" db:"category_name"`
	CategoryIcon    *string    `json:"category_icon,omitempty" db:"category_icon"`
	Amount          float64    `json:"amount" db:"amount"`
	Type            string     `json:"type" db:"type"` // 'income' or 'expense'
	Note            *string    `json:"note" db:"note"`
	TransactionDate string     `json:"transaction_date" db:"transaction_date"` // YYYY-MM-DD
	IsRecurring     bool       `json:"is_recurring" db:"is_recurring"`
	RecurringRule   *string    `json:"recurring_rule" db:"recurring_rule"`
	SyncStatus      string     `json:"sync_status" db:"sync_status"`
	CreatedAt       time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt       time.Time  `json:"updated_at" db:"updated_at"`
}

type CreateTransactionRequest struct {
	ID              *string  `json:"id,omitempty"` // For sync or client-generated UUID
	AccountID       *string  `json:"account_id"`
	CategoryID      *string  `json:"category_id"`
	Amount          float64  `json:"amount"`
	Type            string   `json:"type"` // 'income' or 'expense'
	Note            *string  `json:"note"`
	TransactionDate string   `json:"transaction_date"` // YYYY-MM-DD
	IsRecurring     bool     `json:"is_recurring"`
	RecurringRule   *string  `json:"recurring_rule"`
	UpdatedAt       *string  `json:"updated_at,omitempty"`
}

type MonthlySummary struct {
	TotalIncome      float64 `json:"total_income"`
	TotalExpense     float64 `json:"total_expense"`
	NetSavings       float64 `json:"net_savings"`
	TransactionCount int     `json:"transaction_count"`
}

type SyncBatchRequest struct {
	Transactions []CreateTransactionRequest `json:"transactions"`
}
