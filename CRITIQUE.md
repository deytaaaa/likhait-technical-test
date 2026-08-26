# Codebase Critique

Notes gathered while working through `TICKETS.md`. Split into what this branch
changes and what it deliberately only records, because several of the
remaining items are product decisions rather than defects.

## Fixed in this branch

### Editing an expense could not change its category

`updateExpense` sent the category by **name**:

```ts
body: JSON.stringify({ expense: data })   // data.category === "Food"
```

`expense_params` only permits `:category_id`, so Rails dropped `category` as an
unpermitted parameter, returned `200 OK`, and left the category untouched. The
UI then refetched and re-rendered the unchanged value, so the edit appeared to
apply and silently reverted. `createExpense` already resolved the name to an id;
that logic is now a shared `toExpensePayload` helper used by both calls, which
also strips keys the caller did not supply so a partial update stays partial.

### Dates rendered one day early west of UTC

`new Date("2026-08-25")` is specified to parse as UTC midnight, but
`getFullYear`/`getMonth`/`getDate` read it back in the viewer's local zone. Any
negative UTC offset shifts the calendar day backwards, so an expense dated the
1st renders as the last day of the previous month and lands in the wrong bucket
in `groupExpensesByDay`. Added `parseLocalDate`, which builds the date from its
parts. Invisible from UTC+8, wrong for anyone in the Americas.

### Deleting a category destroyed its expenses

`has_many :expenses, dependent: :destroy` meant removing a category deleted
every expense filed under it, with no confirmation and no way back. It also
contradicted `db/init.sql`, which declared the same foreign key
`ON DELETE RESTRICT`. Now `:restrict_with_error`.

## Recorded, not changed

### Amount and description accept anything

`Expense` validates neither, so `amount: -100` and `description: ""` both
persist. This is not an oversight in the tests - the suite asserts it:

```ruby
it "with negative amounts" do
  expect { post "/api/expenses", params: invalid_params, as: :json }
    .to change(Expense, :count).by(1)
  expect(response).to have_http_status(:created)
end
```

Two examples named "with invalid parameters" encode the invalid case as the
expected outcome. Adding `numericality: { greater_than: 0 }` and
`presence: true` is a two-line change, but it turns those green tests red, and
rewriting a test that asserts the opposite of what you are about to implement
is a conversation to have with whoever wrote it rather than a unilateral fix. A
negative amount may even be intentional shorthand for a refund - in which case
the fix is a documented `kind` column, not a validation.

### CORS allows every origin

```ruby
origins "*"
resource "*", headers: :any, methods: [ :get, :post, :put, :patch, :delete, :options, :head ]
```

Any site a user visits can call this API from their browser. Harmless while
everything is local and unauthenticated, but the day a session cookie or token
is added this becomes the vulnerability. Should read an allowlist from `ENV`,
defaulting to the dev origin.

### The month endpoint returns the whole month

`GET /api/expenses?year=&month=` has no limit and no pagination; the seeded
data averages ~170 rows per month and the client paginates what it already
downloaded. Fine at this size, and pagination is not free - the totals in
`CategoryBreakdown` are computed client-side from the full set, so paginating
the endpoint means moving aggregation to the server too.

### Aggregation runs on the client

`HistoryPage` reduces the expense array to build the category breakdown. A
`GROUP BY` would be cheaper and would survive pagination. Same trade-off as
above; worth doing together, not separately.

### `:unprocessable_entity` is deprecated

Rack now warns on every use: "Status code :unprocessable_entity is deprecated
... Please use :unprocessable_content instead." Left consistent with the
existing controller rather than half-migrated; worth one sweep.

### No frontend test tooling

`package.json` has no `test` script and no test dependencies, so every frontend
behaviour added here - the category form's validation, the future-date rule,
the date-parsing fix above - is covered only by the backend suite and manual
checks. Vitest plus Testing Library would fit the existing Vite setup with no
configuration to speak of. The date parsing bug in particular is exactly the
kind a three-line unit test pins down permanently.

### `Expense.find` raises without a rescue

`update` and `destroy` call `Expense.find` bare. Rails maps
`RecordNotFound` to a 404 through `config.action_dispatch.rescue_responses`, so
the status is right, but the body is an HTML error page rather than the
`{ errors: [...] }` shape every other failure returns. A `rescue_from` in
`ApplicationController` would make the API uniform.

### `shoulda-matchers` is installed but never configured

It is in the `:test` group of the `Gemfile` and no `RSpec.configure` block sets
it up, so `validate_presence_of` and friends are unavailable. Either wire it up
or drop the dependency.

## Environment issues

Everything that stopped the project from starting or the suite from running is
detailed in the `chore/dev-environment` PR: `db/init.sql` shadowing the Rails
migrations, both lockfiles missing their Linux platform entries, `libyaml-dev`
missing from the backend image, CRLF line endings breaking `bin/` scripts
inside the container, the CI workflow sitting where GitHub never reads it, and
`rails_helper` letting the suite run against the development database.
