defmodule Web.NavigationComponents do
  use Phoenix.Component
  use Web, :verified_routes
  import Web.CoreComponents

  attr :subject, :any, required: true

  def topbar(assigns) do
    ~H"""
    <nav class="bg-gray-50 dark:bg-gray-600 border-b border-gray-200 px-4 py-2.5 dark:border-gray-700 fixed left-0 right-0 top-0 z-50">
      <div class="flex flex-wrap justify-between items-center">
        <div class="flex justify-start items-center">
          <button
            id="sidebar-toggle"
            data-drawer-backdrop="false"
            data-drawer-target="drawer-navigation"
            data-drawer-toggle="drawer-navigation"
            aria-controls="drawer-navigation"
            class={[
              "p-2 mr-2 text-gray-600 rounded-lg cursor-pointer md:hidden",
              "hover:text-gray-900 hover:bg-gray-100",
              "focus:bg-gray-100 dark:focus:bg-gray-700 focus:ring-2 focus:ring-gray-100",
              "dark:focus:ring-gray-700 dark:text-gray-400 dark:hover:bg-gray-700 dark:hover:text-white"
            ]}
          >
            <.icon name="hero-bars-3-center-left" class="w-6 h-6" />
            <span class="sr-only">Toggle sidebar</span>
          </button>
          <a
            href="https://www.firezone.dev/?utm_source=product"
            class="flex items-center justify-between mr-4"
          >
            <img src={~p"/images/logo.svg"} class="mr-3 h-8" alt="Firezone Logo" />
            <span class="self-center text-2xl font-semibold whitespace-nowrap dark:text-white">
              firezone
            </span>
          </a>
        </div>
        <div class="flex items-center lg:order-2">
          <.dropdown id="user-menu">
            <:button>
              <span class="sr-only">Open user menu</span>
              <.gravatar size={25} email={@subject.identity.provider_identifier} class="rounded-full" />
            </:button>
            <:dropdown>
              <.subject_dropdown subject={@subject} />
            </:dropdown>
          </.dropdown>
        </div>
      </div>
    </nav>
    """
  end

  attr :subject, :any, required: true

  def subject_dropdown(assigns) do
    ~H"""
    <div class="py-3 px-4">
      <span class="block text-sm font-semibold text-gray-900 dark:text-white">
        <%= @subject.actor.name %>
      </span>
      <span class="block text-sm text-gray-900 truncate dark:text-white">
        <%= @subject.identity.provider_identifier %>
      </span>
    </div>
    <ul class="py-1 text-gray-700 dark:text-gray-300" aria-labelledby="user-menu-dropdown">
      <li>
        <a
          href="#"
          class="block py-2 px-4 text-sm hover:bg-gray-100 dark:hover:bg-gray-600 dark:text-gray-400 dark:hover:text-white"
        >
          Account settings
        </a>
      </li>
    </ul>
    <ul class="py-1 text-gray-700 dark:text-gray-300" aria-labelledby="user-menu-dropdown">
      <li>
        <a
          href={~p"/#{@subject.account}/sign_out"}
          class="block py-2 px-4 text-sm hover:bg-gray-100 dark:hover:bg-gray-600 dark:hover:text-white"
        >
          Sign out
        </a>
      </li>
    </ul>
    """
  end

  slot :bottom, required: false
  attr :collapsed, :boolean, required: true

  slot :inner_block,
    required: true,
    doc: "The items for the navigation bar should use `sidebar_item` component."

  def sidebar(%{collapsed: true} = assigns) do
    ~H"""
    <aside
      class={~w[
        flex flex-col justify-between
        transition-transform left-0 top-0 -translate-x-full
        fixed top-0 left-0 z-40
        w-16 h-screen
        pt-14 pb-8
        transition-transform -translate-x-full
        bg-white border-r border-gray-200
        md:translate-x-0
        dark:bg-gray-800 dark:border-gray-700 transform-none]}
      aria-label="Sidenav"
      id="drawer-navigation">
      <.sidebar_handler id="drawer-navigation"  aside_collapsed={@collapsed} />
      <div class="overflow-y-auto py-5 px-3 h-full bg-white dark:bg-gray-800">
        <ul class="space-y-2">
          <%= render_slot(@inner_block) %>
        </ul>
      </div>
      <div class="relative flex items-center group flex-1 w-full flex-col cursor-pointer">
        <div id="collapsed-status" class="relative w-8 h-8 rounded-lg flex items-center justify-center">
          <svg class="w-6 h-6" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
            <path stroke-linecap="round" stroke-linejoin="round" d="M9.348 14.651a3.75 3.75 0 010-5.303m5.304 0a3.75 3.75 0 010 5.303m-7.425 2.122a6.75 6.75 0 010-9.546m9.546 0a6.75 6.75 0 010 9.546M5.106 18.894c-3.808-3.808-3.808-9.98 0-13.789m13.788 0c3.808 3.808 3.808 9.981 0 13.79M12 12h.008v.007H12V12zm.375 0a.375.375 0 11-.75 0 .375.375 0 01.75 0z"></path>
          </svg>
          <%= render_slot(@bottom) %>
        </div>
      </div>
    </aside>
    """
  end
  def sidebar(assigns) do
    ~H"""
    <aside phx-hook="Aside" class={~w[
        transition-transform left-0 top-0 -translate-x-full
        transition-all
        fixed top-0 left-0 z-40
        w-64 h-screen
        pt-14 pb-8
        transition-transform -translate-x-full
        bg-white border-r border-gray-200
        md:translate-x-0
        group not-collapsed
        dark:bg-gray-800 dark:border-gray-700 transform-none]} aria-label="Sidenav" id="drawer-navigation" aria-modal="dialog" aria-label="SideNav">
      <.sidebar_handler id="drawer-navigation"  aside_collapsed={@collapsed} />
      <div class="overflow-y-auto py-5 px-3 h-full bg-white dark:bg-gray-800">
        <ul class="space-y-2">
          <%= render_slot(@inner_block) %>
        </ul>
      </div>

      <%= render_slot(@bottom) %>
    </aside>
    """
  end

  def main_ml_class(true = _temporary_assigns_aside_collapsed), do: "md:ml-16"
  def main_ml_class(false = _temporary_assigns_aside_collapsed), do: "md:ml-64"

  attr :aside_collapsed, :boolean, required: true

  defp sidebar_handler(assigns) do
    rotate = if assigns.aside_collapsed,
      do: "" , else: "rotate-180"

    assigns = Map.put(assigns, :rotate, rotate)
    ~H"""
    <div
      phx-click="toggle-collapse-menu"
      data-drawer-backdrop="false"
      data-drawer-show="drawer-navigation"
      class={
        ~w[cursor-pointer flex items-center justify-center absolute w-6 h-16 hover:bg-gray-50 bg-white border border-gray-200 inset-y-1/2 rounded-full transition-all #{"right-[-12px] "}]
      }
    >
      <svg
        class={~w[w-4 h-4 text-red-500 dark:text-red-400 #{@rotate}]}
        xmlns="http://www.w3.org/2000/svg"
        fill="none"
        viewBox="0 0 24 24"
        stroke-width="1.5"
        stroke="currentColor"
      >
        <path
          stroke-linecap="round"
          stroke-linejoin="round"
          d="M11.25 4.5l7.5 7.5-7.5 7.5m-6-15l7.5 7.5-7.5 7.5"
        />
      </svg>
    </div>
    """
  end

  attr :id, :string, required: true, doc: "ID of the nav group container"
  slot :button, required: true
  slot :dropdown, required: true

  def dropdown(assigns) do
    ~H"""
    <button
      type="button"
      class={[
        "flex mx-3 text-sm bg-gray-800 rounded-full md:mr-0",
        "focus:ring-4 focus:ring-gray-300 dark:focus:ring-gray-600"
      ]}
      id={"#{@id}-button"}
      aria-expanded="false"
      data-dropdown-toggle={"#{@id}-dropdown"}
    >
      <%= render_slot(@button) %>
    </button>
    <div
      class={[
        "hidden",
        "z-50 my-4 w-56 text-base list-none bg-white rounded",
        "divide-y divide-gray-100 shadow",
        "dark:bg-gray-700 dark:divide-gray-600 rounded-xl"
      ]}
      id={"#{@id}-dropdown"}
    >
      <%= render_slot(@dropdown) %>
    </div>
    """
  end

  attr :icon, :string, required: true
  attr :navigate, :string, required: true
  attr :section, :atom, required: true
  slot :inner_block, required: true

  def sidebar_item(assigns) do
    assigns = add_active_color_to_assign(assigns)

    ~H"""
    <li>
      <.link navigate={@navigate} class={~w[
      flex items-center p-2
      text-base font-medium
      rounded-lg
      hover:bg-gray-100
      dark:text-white dark:hover:bg-gray-700 group text-#{@active_color}]}>
        <.icon name={@icon} class={~w[
        w-6 h-6
        transition duration-75

        dark:text-gray-400 dark:group-hover:text-white text-#{@active_color}]} />
        <span class="ml-3 group-[&.not-collapsed]:block hidden">
          <%= render_slot(@inner_block) %>
        </span>
      </.link>
    </li>
    """
  end

  defp add_active_color_to_assign(assigns) do
    %{phoenix_live_view: {section, _, _, _}} =
      Phoenix.Router.route_info(Web.Router, "GET", assigns.navigate, nil)

    is_active? = section == assigns.section
    active_color = if is_active?, do: "orange-500", else: "gray-900"
    Map.put(assigns, :active_color, active_color)
  end

  attr :id, :string, required: true, doc: "ID of the nav group container"
  attr :icon, :string, required: true
  # attr :navigate, :string, required: true
  attr :aside_collapsed, :boolean, required: true

  slot :name, required: true

  slot :item, required: true do
    attr :navigate, :string, required: true
  end
  attr :section, :atom, required: true

  def sidebar_item_group(%{aside_collapsed: true} = assigns) do
    is_active = sidebar_item_group_active?(assigns.item, assigns.section)
    |> IO.inspect()
    active_color = if is_active, do: "orange-500", else: "gray-900"
    assigns = Map.put(assigns, :active_color, active_color)

    ~H"""
    <li class="group absolute z-40">
      <button
        class={~w[
          flex items-center p-2 w-auto group rounded-lg
          text-base font-medium text-#{@active_color}
          transition duration-75
          hover:bg-gray-100 dark:text-white dark:hover:bg-gray-700]}
      >
        <.icon name={@icon} class={~w[
          w-6 h-6 text-#{@active_color}
          transition duration-75
          group-hover:text-gray-900
          dark:text-gray-400 dark:group-hover:text-white]} />
      </button>
      <ul
        id={"dropdown-#{@id}"}
        class="z-40 group-hover:block ml-10 absolute shadow-md hidden top-0  bg-white divide-y divide-gray-100 rounded-lg shadow w-44 dark:bg-gray-700"
      >
        <li :for={item <- @item}>
          <% item = add_active_color_to_assign(Map.put(item, :section, @section)) %>
          <.link navigate={item.navigate} class={~w[
              flex items-center p-2  w-full group
              text-base font-medium text-#{item.active_color}
              transition duration-75
              hover:bg-gray-100 dark:text-white dark:hover:bg-gray-700]}>
            <%= render_slot(item) %>
          </.link>
        </li>
      </ul>
    </li>
    """
  end

  defp sidebar_item_group_active?(items, section) do
    Enum.any?(items, fn item ->
      %{phoenix_live_view: {item_section, _, _, _}} =
        Phoenix.Router.route_info(Web.Router, "GET", item.navigate, nil)

      item_section == section
    end)
  end

  def sidebar_item_group(assigns) do
    ~H"""
    <li>
      <button
        type="button"
        class={~w[
          flex items-center p-2 w-full group rounded-lg
          text-base font-medium text-gray-900
          transition duration-75
          hover:bg-gray-100 dark:text-white dark:hover:bg-gray-700]}
        aria-controls={"dropdown-#{@id}"}
        data-collapse-toggle={"dropdown-#{@id}"}
      >
        <.icon name={@icon} class={~w[
          w-6 h-6 text-gray-500
          transition duration-75
          group-hover:text-gray-900
          dark:text-gray-400 dark:group-hover:text-white]} />
        <span class="flex-1 ml-3 text-left whitespace-nowrap group not-collapsed">
          <%= render_slot(@name) %>
        </span>
        <.icon name="hero-chevron-down-solid" class={~w[
          w-6 h-6 text-gray-500
          transition duration-75
          group-hover:text-gray-900
          dark:text-gray-400 dark:group-hover:text-white]} />
      </button>
      <ul id={"dropdown-#{@id}"} class="py-2 space-y-2">
        <li :for={item <- @item}>
        <% item = add_active_color_to_assign(Map.put(item, :section, @section)) %>
          <.link navigate={item.navigate} class={~w[
              flex items-center p-2 pl-11 w-full group rounded-lg
              text-base font-medium text-#{item.active_color}
              transition duration-75
              hover:bg-gray-100 dark:text-white dark:hover:bg-gray-700]}>
            <%= render_slot(item) %>
          </.link>
        </li>
      </ul>
    </li>
    """
  end

  @doc """
  Renders breadcrumbs section, for elements `<.breadcrumb />` component should be used.
  """
  attr :account, :any,
    required: false,
    default: nil,
    doc: "Account assign which will be used to fetch the home path."

  # TODO: remove this attribute
  attr :home_path, :string, required: false, doc: "The path for to the home page for a user."
  slot :inner_block, required: true, doc: "Breadcrumb entries"

  def breadcrumbs(assigns) do
    ~H"""
    <nav class="p-4 pb-0" class="flex" aria-label="Breadcrumb">
      <ol class="inline-flex items-center space-x-1 md:space-x-2">
        <li class="inline-flex items-center">
          <.link
            navigate={if @account, do: ~p"/#{@account}/dashboard", else: @home_path}
            class="inline-flex items-center text-gray-700 hover:text-gray-900 dark:text-gray-300 dark:hover:text-white"
          >
            <.icon name="hero-home-solid" class="w-4 h-4 mr-2" /> Home
          </.link>

          <%= render_slot(@inner_block) %>
        </li>
      </ol>
    </nav>
    """
  end

  @doc """
  Renders a single breadcrumb entry. should be wrapped in <.breadcrumbs> component.
  """
  slot :inner_block, required: true, doc: "The label for the breadcrumb entry."
  attr :path, :string, required: true, doc: "The path for the breadcrumb entry."

  def breadcrumb(assigns) do
    ~H"""
    <li class="inline-flex items-center">
      <div class="flex items-center text-gray-700 dark:text-gray-300">
        <.icon name="hero-chevron-right-solid" class="w-6 h-6" />
        <.link
          navigate={@path}
          class="ml-1 text-sm font-medium text-gray-700 hover:text-gray-900 md:ml-2 dark:text-gray-300 dark:hover:text-white"
        >
          <%= render_slot(@inner_block) %>
        </.link>
      </div>
    </li>
    """
  end

  @doc """
  Renders a back navigation link.

  ## Examples

      <.back navigate={~p"/posts"}>Back to posts</.back>
  """
  attr :navigate, :any, required: true
  slot :inner_block, required: true

  def back(assigns) do
    ~H"""
    <div class="mt-16">
      <.link
        navigate={@navigate}
        class="text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
      >
        <.icon name="hero-arrow-left-solid" class="h-3 w-3" />
        <%= render_slot(@inner_block) %>
      </.link>
    </div>
    """
  end
end
