defmodule Web.Plugs.TemporaryAssigns do
  import Phoenix.Component

  def on_mount(:temporary_assigns, params, session, socket) do
    aside_collapsed = get_in(socket.assigns, [:temporary_assigns, :aside_collapsed])

    socket =
      assign(socket, :temporary_assigns, section: socket.view, aside_collapsed: !!aside_collapsed)

    {:cont, socket}
  end
end
