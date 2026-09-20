package spaces

import (
	"time"

	"github.com/google/uuid"
)

type Space struct {
	ID        uuid.UUID `json:"id" db:"id"`
	UserID    uuid.UUID `json:"user_id" db:"user_id"`
	Type      string    `json:"type" db:"type"` // 'personal' or 'business'
	Name      string    `json:"name" db:"name"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
}

type CreateSpaceRequest struct {
	Type string `json:"type"` // 'personal' or 'business'
	Name string `json:"name"`
}

type UpdateSpaceRequest struct {
	Name string `json:"name"`
}
