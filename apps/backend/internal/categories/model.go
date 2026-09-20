package categories

import (
	"github.com/google/uuid"
)

type Category struct {
	ID        uuid.UUID `json:"id" db:"id"`
	SpaceID   uuid.UUID `json:"space_id" db:"space_id"`
	Name      string    `json:"name" db:"name"`
	Type      string    `json:"type" db:"type"` // 'income' or 'expense'
	Icon      *string   `json:"icon" db:"icon"`
	IsDefault bool      `json:"is_default" db:"is_default"`
}

type CreateCategoryRequest struct {
	Name string  `json:"name"`
	Type string  `json:"type"` // 'income' or 'expense'
	Icon *string `json:"icon"`
}

type UpdateCategoryRequest struct {
	Name string  `json:"name"`
	Icon *string `json:"icon"`
}
