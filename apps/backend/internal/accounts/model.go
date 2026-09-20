package accounts

import (
	"time"

	"github.com/google/uuid"
)

type Account struct {
	ID        uuid.UUID `json:"id" db:"id"`
	SpaceID   uuid.UUID `json:"space_id" db:"space_id"`
	Name      string    `json:"name" db:"name"`
	Type      string    `json:"type" db:"type"` // 'cash', 'bank', 'ewallet'
	Balance   float64   `json:"balance" db:"balance"`
	Currency  string    `json:"currency" db:"currency"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
}

type CreateAccountRequest struct {
	Name     string  `json:"name"`
	Type     string  `json:"type"` // 'cash', 'bank', 'ewallet'
	Balance  float64 `json:"balance"`
	Currency string  `json:"currency"`
}

type UpdateAccountRequest struct {
	Name    string  `json:"name"`
	Balance float64 `json:"balance"`
}
