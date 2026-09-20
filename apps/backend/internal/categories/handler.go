package categories

import (
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

func (h *Handler) ListBySpace(c *fiber.Ctx) error {
	userID := c.Locals("userId").(string)
	spaceID := c.Params("spaceId")

	var count int
	err := h.db.Get(&count, "SELECT count(*) FROM spaces WHERE id = $1 AND user_id = $2", spaceID, userID)
	if err != nil || count == 0 {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"success": false, "message": "Access denied to space"})
	}

	var list []Category
	err = h.db.Select(&list, "SELECT id, space_id, name, type, icon, is_default FROM categories WHERE space_id = $1 ORDER BY is_default DESC, name ASC", spaceID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"success": false, "message": "Failed to retrieve categories"})
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

	var req CreateCategoryRequest
	if err := c.BodyParser(&req); err != nil || req.Name == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"success": false, "message": "Category name is required"})
	}
	if req.Type != "income" && req.Type != "expense" {
		req.Type = "expense"
	}

	catID := uuid.New()
	_, err = h.db.Exec(
		"INSERT INTO categories (id, space_id, name, type, icon, is_default) VALUES ($1, $2, $3, $4, $5, false)",
		catID, spaceID, req.Name, req.Type, req.Icon,
	)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"success": false, "message": "Failed to create category"})
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"success": true,
		"data": Category{
			ID:        catID,
			SpaceID:   uuid.MustParse(spaceID),
			Name:      req.Name,
			Type:      req.Type,
			Icon:      req.Icon,
			IsDefault: false,
		},
	})
}

func (h *Handler) Update(c *fiber.Ctx) error {
	userID := c.Locals("userId").(string)
	catID := c.Params("id")

	var req UpdateCategoryRequest
	if err := c.BodyParser(&req); err != nil || req.Name == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"success": false, "message": "Category name is required"})
	}

	res, err := h.db.Exec(`
		UPDATE categories 
		SET name = $1, icon = $2 
		WHERE id = $3 AND space_id IN (SELECT id FROM spaces WHERE user_id = $4)
	`, req.Name, req.Icon, catID, userID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"success": false, "message": "Failed to update category"})
	}

	rows, _ := res.RowsAffected()
	if rows == 0 {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"success": false, "message": "Category not found"})
	}

	return c.JSON(fiber.Map{"success": true, "message": "Category updated successfully"})
}

func (h *Handler) Delete(c *fiber.Ctx) error {
	userID := c.Locals("userId").(string)
	catID := c.Params("id")

	res, err := h.db.Exec(`
		DELETE FROM categories 
		WHERE id = $1 AND space_id IN (SELECT id FROM spaces WHERE user_id = $2)
	`, catID, userID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"success": false, "message": "Failed to delete category"})
	}

	rows, _ := res.RowsAffected()
	if rows == 0 {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"success": false, "message": "Category not found"})
	}

	return c.JSON(fiber.Map{"success": true, "message": "Category deleted successfully"})
}
