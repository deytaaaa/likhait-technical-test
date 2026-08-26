/**
 * API service for communicating with the backend
 */

import { Category, Expense, ExpenseFormData } from "../types";

const API_BASE_URL = "http://localhost:3000/api";

/**
 * Turn a failed response into an Error carrying the server's message.
 *
 * The API renders validation failures as `{ "errors": ["Name can't be blank"] }`.
 * Without this the UI could only ever show a generic "Failed to ..." string and
 * the user would have no idea which field was rejected or why.
 */
async function toError(response: Response, fallback: string): Promise<Error> {
  try {
    const body = await response.json();
    if (Array.isArray(body?.errors) && body.errors.length > 0) {
      return new Error(body.errors.join(", "));
    }
  } catch {
    // Non-JSON body (a 500 HTML page, an empty response): fall through.
  }
  return new Error(fallback);
}

/**
 * Fetch expenses for a specific year and month
 */
export async function getExpenses(
  year: number,
  month: number,
): Promise<Expense[]> {
  const response = await fetch(
    `${API_BASE_URL}/expenses?year=${year}&month=${month}`,
  );
  if (!response.ok) {
    throw await toError(response, "Failed to fetch expenses");
  }
  return response.json();
}

/**
 * Fetch all categories
 */
export async function fetchCategories(): Promise<Category[]> {
  const response = await fetch(`${API_BASE_URL}/categories`);
  if (!response.ok) {
    throw await toError(response, "Failed to fetch categories");
  }
  return response.json();
}

/**
 * Create a new category
 */
export async function createCategory(name: string): Promise<Category> {
  const response = await fetch(`${API_BASE_URL}/categories`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ category: { name } }),
  });

  if (!response.ok) {
    throw await toError(response, "Failed to create category");
  }

  return response.json();
}

/**
 * Translate a form payload into the shape the API accepts.
 *
 * The form carries the category by name while `expense_params` on the server
 * only permits `category_id`, so the name has to be resolved to an id here or
 * Rails discards it as an unpermitted parameter.
 */
async function toExpensePayload(data: Partial<ExpenseFormData>) {
  const payload: Record<string, unknown> = {
    description: data.description,
    amount: data.amount,
    date: data.date,
  };

  if (data.category !== undefined) {
    const categories = await fetchCategories();
    payload.category_id = categories.find((c) => c.name === data.category)?.id;
  }

  // Drop keys the caller did not supply so a partial update stays partial.
  Object.keys(payload).forEach((key) => {
    if (payload[key] === undefined) delete payload[key];
  });

  return payload;
}

/**
 * Create a new expense
 */
export async function createExpense(data: ExpenseFormData): Promise<Expense> {
  const expenseData = await toExpensePayload(data);

  const response = await fetch(`${API_BASE_URL}/expenses`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ expense: expenseData }),
  });

  if (!response.ok) {
    throw await toError(response, "Failed to create expense");
  }

  return response.json();
}

/**
 * Update an existing expense
 */
export async function updateExpense(
  id: number,
  data: Partial<ExpenseFormData>,
): Promise<Expense> {
  const expenseData = await toExpensePayload(data);

  const response = await fetch(`${API_BASE_URL}/expenses/${id}`, {
    method: "PUT",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ expense: expenseData }),
  });

  if (!response.ok) {
    throw await toError(response, "Failed to update expense");
  }

  return response.json();
}

/**
 * Delete an expense
 */
export async function deleteExpense(id: number): Promise<void> {
  const response = await fetch(`${API_BASE_URL}/expenses/${id}`, {
    method: "DELETE",
  });

  if (!response.ok) {
    throw await toError(response, "Failed to delete expense");
  }
}
