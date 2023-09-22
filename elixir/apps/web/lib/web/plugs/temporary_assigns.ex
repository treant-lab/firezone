defmodule Web.Plugs.TemporaryAssigns do
  import Phoenix.Component

  def init(args), do: args

  def call(conn, _args), do: {:ok, conn}

  def on_mount(:temporary_assigns, _params, _session, socket) do
    aside_collapsed = get_in(socket.assigns, [:temporary_assigns, :aside_collapsed])

    socket =
      assign(socket, :temporary_assigns, section: socket.view, aside_collapsed: !!aside_collapsed)

    {:cont, socket}
  end
end
