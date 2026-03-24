# Functional Core Pattern

Build pure functional modules that separate business logic from side effects.

## Pattern Overview

A functional core is a module containing pure functions that:
- Take plain data structures as input
- Return plain data structures as output
- Have no side effects (no DB calls, no external APIs, no randomness)
- Are easily testable in isolation

## Structure

```elixir
defmodule MyApp.FunctionalCore do
  @moduledoc """
  Pure business logic for [domain concept].
  All functions are pure and side-effect free.
  """

  @doc """
  Creates/initializes the core data structure.
  """
  def new(params) do
    # Transform input into core representation
  end

  @doc """
  Core business logic operation.
  """
  def operation(state, params) do
    # Pure transformation
  end

  @doc """
  Converts internal state to output format.
  """
  def show(state) do
    # Format for display/serialization
  end
end
```

## Key Principles

1. **Pure Functions Only**
   - No `Repo` calls
   - No HTTP requests
   - No `DateTime.now()` or random values
   - Pass time/randomness as parameters if needed

2. **Data In, Data Out**
   - Accept simple types (strings, integers, maps, lists)
   - Return simple types
   - Avoid structs unless they're simple data containers

3. **Testability**
   - Every function can be tested without mocks
   - Same input always produces same output
   - No setup/teardown needed

4. **Boundary Functions**
   - `new/1` - Initialize from external input
   - `operation/2` - Core transformations
   - `show/1` - Convert to output format

## Example: Counter

```elixir
defmodule Adder.Counter do
  def new(value) when is_binary(value) do
    String.to_integer(value)
  end

  def add(value, addend) do
    value + addend
  end

  def show(value) do
    Integer.to_string(value)
  end
end
```

## Usage in LiveView

Keep the functional core separate from LiveView:

```elixir
defmodule MyAppWeb.CounterLive do
  use MyAppWeb, :live_view
  alias MyApp.Counter

  def mount(_params, _session, socket) do
    {:ok, assign(socket, count: Counter.new("0"))}
  end

  def handle_event("increment", _params, socket) do
    new_count = Counter.add(socket.assigns.count, 1)
    {:noreply, assign(socket, count: new_count)}
  end
end
```

## Testing Pattern

```elixir
defmodule MyApp.FunctionalCoreTest do
  use ExUnit.Case
  alias MyApp.FunctionalCore

  describe "new/1" do
    test "initializes from valid input" do
      assert FunctionalCore.new("input") == expected_output
    end
  end

  describe "operation/2" do
    test "transforms state correctly" do
      state = FunctionalCore.new("input")
      assert FunctionalCore.operation(state, params) == expected_result
    end
  end
end
```

## When to Use

Use functional cores for:
- ✅ Calculations and transformations
- ✅ Business rules and validations
- ✅ State machines
- ✅ Data formatting and parsing

Don't use for:
- ❌ Database operations (use contexts)
- ❌ External API calls (use separate modules)
- ❌ File I/O
- ❌ Process management

## Benefits

1. **Easier Testing** - No database, no external dependencies
2. **Better Reusability** - Can use in LiveView, controllers, background jobs
3. **Simpler Reasoning** - No hidden dependencies or side effects
4. **Faster Execution** - Pure computation, no I/O waits
