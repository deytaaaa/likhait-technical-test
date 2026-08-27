/**
 * Form component for adding/editing expenses
 */

import React from "react";
import { ExpenseFormData } from "../types";
import { TextField, SelectBox, Button } from "../vibes";
import { COLORS } from "../constants/colors";
import { useExpenseForm, today } from "../hooks/useExpenseForm";
import { useCategories } from "../contexts/CategoriesContext";

interface ExpenseFormProps {
  initialData?: Partial<ExpenseFormData>;
  onSubmit: (data: ExpenseFormData) => Promise<void>;
  onCancel?: () => void;
  submitLabel?: string;
}

export function ExpenseForm({
  initialData,
  onSubmit,
  onCancel,
  submitLabel = "Add Expense",
}: ExpenseFormProps) {
  const {
    formData,
    errors,
    submitError,
    isSubmitting,
    handleChange,
    handleSubmit,
  } = useExpenseForm({
    initialData,
    onSubmit,
  });
  const { categories, loading: categoriesLoading } = useCategories();

  const formStyle: React.CSSProperties = {
    display: "flex",
    flexDirection: "column",
    gap: "1rem",
  };

  const buttonGroupStyle: React.CSSProperties = {
    display: "flex",
    gap: "0.5rem",
    marginTop: "0.5rem",
  };

  const submitErrorStyle: React.CSSProperties = {
    fontSize: "0.875rem",
    color: COLORS.danger,
    backgroundColor: COLORS.background.card,
    border: `1px solid ${COLORS.danger}`,
    borderRadius: "0.375rem",
    padding: "0.5rem 0.75rem",
  };

  // Sourced from /api/categories rather than a hardcoded list, so categories
  // added through the Add Category modal are immediately selectable here.
  const categoryOptions = categories.map((category) => ({
    value: category.name,
    label: category.name,
  }));

  return (
    <form onSubmit={handleSubmit} style={formStyle}>
      <TextField
        label="Amount"
        type="number"
        step="0.01"
        placeholder="0.00"
        value={formData.amount}
        onChange={(e) => handleChange("amount", e.target.value)}
        error={errors.amount}
        fullWidth
        required
      />

      <TextField
        label="Description"
        type="text"
        placeholder="Enter description"
        value={formData.description}
        onChange={(e) => handleChange("description", e.target.value)}
        error={errors.description}
        fullWidth
        required
      />

      <SelectBox
        label="Category"
        options={categoryOptions}
        value={formData.category}
        onChange={(e) => handleChange("category", e.target.value)}
        error={errors.category}
        disabled={categoriesLoading}
        fullWidth
        required
      />

      {/* `max` stops the picker offering future days; useExpenseForm repeats
          the check because the attribute does not stop a typed-in date, and
          the model enforces it again server-side. */}
      <TextField
        label="Date"
        type="date"
        value={formData.date}
        max={today()}
        onChange={(e) => handleChange("date", e.target.value)}
        error={errors.date}
        fullWidth
        required
      />

      {submitError && (
        <div style={submitErrorStyle} role="alert">
          {submitError}
        </div>
      )}

      <div style={buttonGroupStyle}>
        <Button
          type="submit"
          variant="primary"
          disabled={isSubmitting}
          fullWidth
        >
          {isSubmitting ? "Submitting..." : submitLabel}
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
