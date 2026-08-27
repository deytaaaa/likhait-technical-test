/**
 * Form component for creating an expense category
 */

import React, { useState } from "react";
import { TextField, Button } from "../vibes";
import { COLORS } from "../constants/colors";
import { useCategories } from "../contexts/CategoriesContext";
import { Category } from "../types";

const MAX_NAME_LENGTH = 100;

interface CategoryFormProps {
  onCreated?: (category: Category) => void;
  onCancel?: () => void;
}

export function CategoryForm({ onCreated, onCancel }: CategoryFormProps) {
  const { categories, addCategory } = useCategories();
  const [name, setName] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Mirrors the server-side rules in app/models/category.rb so the common
  // mistakes are caught without a round trip. The server stays authoritative:
  // it is the only thing that can see a category another tab just added.
  const validate = (): string | null => {
    const trimmed = name.trim();

    if (!trimmed) {
      return "Category name is required";
    }
    if (trimmed.length > MAX_NAME_LENGTH) {
      return `Category name must be ${MAX_NAME_LENGTH} characters or fewer`;
    }
    if (
      categories.some((c) => c.name.toLowerCase() === trimmed.toLowerCase())
    ) {
      return `"${trimmed}" already exists`;
    }
    return null;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    const validationError = validate();
    if (validationError) {
      setError(validationError);
      return;
    }

    setIsSubmitting(true);
    try {
      const category = await addCategory(name.trim());
      setName("");
      setError(null);
      onCreated?.(category);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to create category");
    } finally {
      setIsSubmitting(false);
    }
  };

  const formStyle: React.CSSProperties = {
    display: "flex",
    flexDirection: "column",
    gap: "1rem",
  };

  const hintStyle: React.CSSProperties = {
    fontSize: "0.75rem",
    color: COLORS.text.secondary,
    marginTop: "-0.5rem",
  };

  const buttonGroupStyle: React.CSSProperties = {
    display: "flex",
    gap: "0.5rem",
    marginTop: "0.5rem",
  };

  return (
    <form onSubmit={handleSubmit} style={formStyle}>
      <TextField
        label="Category Name"
        type="text"
        placeholder="e.g. Groceries"
        value={name}
        onChange={(e) => {
          setName(e.target.value);
          if (error) setError(null);
        }}
        error={error ?? undefined}
        maxLength={MAX_NAME_LENGTH}
        fullWidth
        autoFocus
        required
      />
      <span style={hintStyle}>
        Available immediately in the expense form once saved.
      </span>

      <div style={buttonGroupStyle}>
        <Button type="submit" variant="primary" disabled={isSubmitting} fullWidth>
          {isSubmitting ? "Saving..." : "Add Category"}
        </Button>
        {onCancel && (
          <Button
            type="button"
            variant="secondary"
            onClick={onCancel}
            disabled={isSubmitting}
          >
            Cancel
          </Button>
        )}
      </div>
    </form>
  );
}
