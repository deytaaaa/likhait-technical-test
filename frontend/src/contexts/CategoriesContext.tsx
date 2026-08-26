/**
 * Shared access to the category list.
 *
 * Categories are now created at runtime, so the list can no longer be a
 * compile-time constant - every consumer has to see the same server-backed
 * collection and the same refresh. `ExpenseForm` is rendered from two
 * unrelated places (`HistoryPage` and `CalendarExpenseTable`), so passing the
 * list down as props would force `CalendarExpenseTable` to accept and forward
 * data it never uses.
 */

import React, {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
} from "react";
import { Category } from "../types";
import { createCategory, fetchCategories } from "../services/api";

interface CategoriesContextValue {
  categories: Category[];
  loading: boolean;
  error: string | null;
  refresh: () => Promise<void>;
  addCategory: (name: string) => Promise<Category>;
}

const CategoriesContext = createContext<CategoriesContextValue | undefined>(
  undefined,
);

export function CategoriesProvider({
  children,
}: {
  children: React.ReactNode;
}) {
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const refresh = useCallback(async () => {
    setLoading(true);
    try {
      setCategories(await fetchCategories());
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load categories");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    refresh();
  }, [refresh]);

  // Splice the new category into local state rather than refetching: the
  // server already returned the created record, and the caller needs it back
  // to preselect it in the expense form.
  const addCategory = useCallback(async (name: string) => {
    const category = await createCategory(name);
    setCategories((prev) =>
      [...prev, category].sort((a, b) => a.name.localeCompare(b.name)),
    );
    return category;
  }, []);

  const value = useMemo(
    () => ({ categories, loading, error, refresh, addCategory }),
    [categories, loading, error, refresh, addCategory],
  );

  return (
    <CategoriesContext.Provider value={value}>
      {children}
    </CategoriesContext.Provider>
  );
}

export function useCategories(): CategoriesContextValue {
  const context = useContext(CategoriesContext);
  if (!context) {
    throw new Error("useCategories must be used within a CategoriesProvider");
  }
  return context;
}
