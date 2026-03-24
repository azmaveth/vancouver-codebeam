---
description: >
  Generate a socket-first delegate component for Phoenix LiveView. This pattern manages
  state on the LiveView's socket rather than using a full Phoenix.LiveComponent. The
  component module provides mount, update, and function component functions that the
  LiveView delegates to.
triggers:
  - component
  - LiveComponent
  - child component
  - delegate component
  - socket component
  - function component
  - extract component
  - new component
---

# Socket-First Delegate Component

## Pattern Overview

This pattern replaces `Phoenix.LiveComponent` with a simpler approach: a plain
`Phoenix.Component` module that manages state directly on the parent LiveView's socket
through delegate functions. Events are namespaced to avoid collisions when composing
multiple components in a single LiveView.

## Pattern Structure

### 1. Component Module (`lib/<app_web>/components/<name>_component.ex`)

A module using `Phoenix.Component` that provides:

- **`mount(socket, initial_args)`** — Initializes state by assigning to the socket. Called from the LiveView's `mount/3`.
- **`update_<name>(socket, event_string)`** — One or more update function clauses, pattern-matched on the event string. Called from the LiveView's `handle_event/3`. Returns the updated socket.
- **Function components** — Render functions with `attr`/`slot` declarations and HEEx templates. Events use a namespace prefix like `"<name>:<action>"` in `phx-click` and similar bindings.

Example:

```elixir
defmodule MyAppWeb.TimerComponent do
  use Phoenix.Component

  def mount(socket, initial_seconds) do
    assign(socket, :timer, initial_seconds)
  end

  def update_timer(socket, "start"), do: ...
  def update_timer(socket, "stop"), do: ...

  attr :value, :integer, required: true
  slot :inner_block
  def timer(assigns) do
    ~H"""
    <div>
      {@value}
      {render_slot(@inner_block)}
    </div>
    """
  end

  def timer_controls(assigns) do
    ~H"""
    <button phx-click="timer:start">Start</button>
    <button phx-click="timer:stop">Stop</button>
    """
  end
end
```

### 2. LiveView (`lib/<app_web>/live/<name>_live.ex`)

A LiveView that delegates to the component:

- **`mount/3`** — Pipes socket through `Component.mount(socket, args)`.
- **`handle_event/3`** — Pattern matches the namespace prefix (e.g., `"timer:" <> event`) and delegates to the component's update function.
- **`render/1`** — Uses the component module's function components.

Example:

```elixir
defmodule MyAppWeb.TimerLive do
  use MyAppWeb, :live_view

  alias MyAppWeb.TimerComponent

  def mount(_params, _session, socket) do
    {:ok, socket |> TimerComponent.mount(60)}
  end

  def handle_event("timer:" <> event, _params, socket) do
    {:noreply, socket |> TimerComponent.update_timer(event)}
  end

  def render(assigns) do
    ~H"""
    <TimerComponent.timer value={@timer}>
      <TimerComponent.timer_controls />
    </TimerComponent.timer>
    """
  end
end
```

## Composability

Multiple socket-first components coexist in a single LiveView. Each namespaces its events, and the LiveView mounts and delegates to each independently:

```elixir
def mount(_params, _session, socket) do
  {:ok, socket |> CounterComponent.mount("0") |> TimerComponent.mount(60)}
end

def handle_event("counter:" <> event, _params, socket) do
  {:noreply, socket |> CounterComponent.update_counter(event)}
end

def handle_event("timer:" <> event, _params, socket) do
  {:noreply, socket |> TimerComponent.update_timer(event)}
end
```

## Instructions

1. Parse the component name and description from the user's request.
2. Identify the app module name by reading `mix.exs` or an existing file under `lib/*_web/`.
3. Determine appropriate state, events, and function components based on the description.
4. Generate the component module with `mount/2`, `update_<name>/2` clauses, and function components. Use `attr` and `slot` declarations. Namespace all `phx-click` (and similar) events with `"<name>:<action>"`.
5. Generate the LiveView module that delegates to the component.
6. Add a route in `router.ex` under the appropriate scope (typically the browser scope with `live "/<name>", <Name>Live`).
7. If the component needs a backing context or schema module, create it under `lib/<app>/` following existing project conventions.
8. Run `mix compile` to verify the code compiles.
