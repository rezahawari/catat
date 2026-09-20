package spaces

import (
	"database/sql"
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

func (h *Handler) ListSpaces(c *fiber.Ctx) error {
	userID := c.Locals("userId").(string)

	var list []Space
	err := h.db.Select(&list, "SELECT id, user_id, type, name, created_at FROM spaces WHERE user_id = $1 ORDER BY created_at ASC", userID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"success": false, "message": "Failed to retrieve spaces"})
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data":    list,
	})
}

func (h *Handler) CreateSpace(c *fiber.Ctx) error {
	userID := c.Locals("userId").(string)
	var req CreateSpaceRequest
	if err := c.BodyParser(&req); err != nil || req.Name == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"success": false, "message": "Invalid space name or type"})
	}

	if req.Type != "personal" && req.Type != "business" {
		req.Type = "business"
	}

	tx, err := h.db.Beginx()
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"success": false, "message": "Database transaction error"})
	}
	defer tx.Rollback()

	spaceID := uuid.New()
	now := time.Now()
	_, err = tx.Exec(
		"INSERT INTO spaces (id, user_id, type, name, created_at) VALUES ($1, $2, $3, $4, $5)",
		spaceID, userID, req.Type, req.Name, now,
	)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"success": false, "message": "Failed to create space"})
	}

	// Auto seed business accounts & categories if business space
	if req.Type == "business" {
		// Default Business Accounts
		businessAccounts := []struct {
			Name string
			Type string
		}{
			{"Kas Usaha (Cash)", "cash"},
			{"Rekening Operasional Bisnis", "bank"},
			{"QRIS / E-Commerce Wallet", "ewallet"},
		}
		for _, acc := range businessAccounts {
			accID := uuid.New()
			_, _ = tx.Exec(
				`INSERT INTO accounts (id, space_id, name, type, balance, currency, created_at) VALUES ($1, $2, $3, $4, 0, 'IDR', $5)`,
				accID, spaceID, acc.Name, acc.Type, now,
			)
		}

		// Default Business Categories
		businessCategories := []struct {
			Name string
			Type string
			Icon string
		}{
			{"Penjualan Barang / Produk", "income", "shopping-cart"},
			{"Pendapatan Jasa / Project", "income", "briefcase"},
			{"Injeksi Modal Usaha", "income", "trending-up"},
			{"Pendapatan Lain-lain", "income", "plus-circle"},
			{"Bahan Baku & Persediaan", "expense", "package"},
			{"Operasional & Utilitas", "expense", "tool"},
			{"Sewa Tempat / Kantor", "expense", "home"},
			{"Gaji Pegawai / Tim", "expense", "users"},
			{"Iklan & Marketing", "expense", "target"},
			{"Logistik & Pengiriman", "expense", "truck"},
			{"Biaya Admin & Pajak", "expense", "file-text"},
			{"Pengeluaran Lainnya", "expense", "more-horizontal"},
		}
		for _, cat := range businessCategories {
			catID := uuid.New()
			_, _ = tx.Exec(
				`INSERT INTO categories (id, space_id, name, type, icon, is_default) VALUES ($1, $2, $3, $4, $5, true)`,
				catID, spaceID, cat.Name, cat.Type, cat.Icon,
			)
		}
	}

	if err := tx.Commit(); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"success": false, "message": "Failed to finalize space creation"})
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"success": true,
		"data": Space{
			ID:        spaceID,
			UserID:    uuid.MustParse(userID),
			Type:      req.Type,
			Name:      req.Name,
			CreatedAt: now,
		},
	})
}

func (h *Handler) GetSpace(c *fiber.Ctx) error {
	userID := c.Locals("userId").(string)
	spaceID := c.Params("id")

	var space Space
	err := h.db.Get(&space, "SELECT id, user_id, type, name, created_at FROM spaces WHERE id = $1 AND user_id = $2", spaceID, userID)
	if err != nil {
		if err == sql.ErrNoRows {
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"success": false, "message": "Space not found"})
		}
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"success": false, "message": "Failed to retrieve space"})
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data":    space,
	})
}

func (h *Handler) UpdateSpace(c *fiber.Ctx) error {
	userID := c.Locals("userId").(string)
	spaceID := c.Params("id")

	var req UpdateSpaceRequest
	if err := c.BodyParser(&req); err != nil || req.Name == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"success": false, "message": "Name is required"})
	}

	res, err := h.db.Exec("UPDATE spaces SET name = $1 WHERE id = $2 AND user_id = $3", req.Name, spaceID, userID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"success": false, "message": "Failed to update space"})
	}

	rows, _ := res.RowsAffected()
	if rows == 0 {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"success": false, "message": "Space not found"})
	}

	return c.JSON(fiber.Map{
		"success": true,
		"message": "Space updated successfully",
	})
}

func (h *Handler) DeleteSpace(c *fiber.Ctx) error {
	userID := c.Locals("userId").(string)
	spaceID := c.Params("id")

	res, err := h.db.Exec("DELETE FROM spaces WHERE id = $1 AND user_id = $2 AND type != 'personal'", spaceID, userID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"success": false, "message": "Failed to delete space"})
	}

	rows, _ := res.RowsAffected()
	if rows == 0 {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"success": false, "message": "Cannot delete default personal space or space not found"})
	}

	return c.JSON(fiber.Map{
		"success": true,
		"message": "Space deleted successfully",
	})
}
