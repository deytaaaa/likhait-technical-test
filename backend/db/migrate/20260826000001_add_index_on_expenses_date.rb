class AddIndexOnExpensesDate < ActiveRecord::Migration[7.2]
  def change
    # /api/expenses both filters and sorts on `date`; without this the month
    # view is a full table scan plus a filesort.
    add_index :expenses, :date
  end
end
