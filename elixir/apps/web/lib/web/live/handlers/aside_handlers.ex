defmodule Web.Live.Handlers.Aside do
  import Phoenix.Component

  def handlers do
    quote do
      def handle_event("toggle-collapse-menu", _params, socket) do
        socket =
          update(
            socket,
            :temporary_assigns,
            &[section: &1[:section], aside_collapsed: !&1[:aside_collapsed]]
          )

        socket =
          push_event(socket, "aside:toggle-collapse-menu", %{
            aside_collapsed: socket.assigns.temporary_assigns[:aside_collapsed]
          })

        {:noreply, socket}
      end

      def handle_event("collapse-menu-state", %{"aside_collapsed" => state}, socket) do
        socket =
          update(
            socket,
            :temporary_assigns,
            &[section: &1[:section], aside_collapsed: state == "true"]
          )

        {:noreply, socket}
      end
    end
  end
end
