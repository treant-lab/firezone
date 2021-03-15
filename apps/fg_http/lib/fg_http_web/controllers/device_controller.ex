defmodule FgHttpWeb.DeviceController do
  @moduledoc """
  Implements the CRUD for a Device
  """

  use FgHttpWeb, :controller
  alias FgHttp.Devices
  alias FgHttpWeb.ErrorHelpers
  require Logger

  plug FgHttpWeb.Plugs.SessionLoader

  def index(conn, _params) do
    devices = Devices.list_devices(conn.assigns.session.id, :with_rules)
    render(conn, "index.html", devices: devices)
  end

  def create(conn, _params) do
    # XXX: Remove device from WireGuard if create isn't successful
    {:device_created, device_attrs} = event_module().create_device()

    attributes =
      Map.merge(%{user_id: conn.assigns.session.id, name: Devices.rand_name()}, device_attrs)

    case Devices.create_device(attributes) do
      {:ok, device} ->
        redirect(conn, to: Routes.device_path(conn, :show, device))

      {:error, %Ecto.Changeset{} = changeset} ->
        msg = ErrorHelpers.aggregated_errors(changeset)

        conn
        |> put_flash(:error, "Error creating device. #{msg}")
        |> redirect(to: Routes.device_path(conn, :index))
    end
  end

  def show(conn, %{"id" => id}) do
    device = Devices.get_device!(id)
    render(conn, "show.html", device: device)
  end

  def edit(conn, %{"id" => id}) do
    device = Devices.get_device!(id)
    changeset = Devices.change_device(device)
    render(conn, "edit.html", device: device, changeset: changeset)
  end

  def update(conn, %{"id" => id, "device" => device_params}) do
    device = Devices.get_device!(id)

    case Devices.update_device(device, device_params) do
      {:ok, device} ->
        conn
        |> put_flash(:info, "Device updated successfully.")
        |> redirect(to: Routes.device_path(conn, :show, device))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", device: device, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    device = Devices.get_device!(id)

    case Devices.delete_device(device) do
      {:ok, _deleted_device} ->
        {:device_deleted, _deleted_pubkey} = event_module().delete_device(device.public_key)

        conn
        |> put_flash(:info, "Device deleted successfully.")
        |> redirect(to: Routes.device_path(conn, :index))

      {:error, msg} ->
        conn
        |> put_flash(:error, "Error deleting device: #{msg}")
        |> redirect(to: Routes.device_path(conn, :index))
    end
  end

  defp event_module do
    Application.get_env(:fg_http, :event_helpers_module)
  end
end
