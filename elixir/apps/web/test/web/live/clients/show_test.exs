defmodule Web.Live.Clients.ShowTest do
  use Web.ConnCase, async: true

  setup do
    account = Fixtures.Accounts.create_account()
    actor = Fixtures.Actors.create_actor(type: :account_admin_user, account: account)
    identity = Fixtures.Auth.create_identity(account: account, actor: actor)
    subject = Fixtures.Auth.create_subject(account: account, actor: actor, identity: identity)

    client = Fixtures.Clients.create_client(account: account, actor: actor, identity: identity)

    %{
      account: account,
      actor: actor,
      identity: identity,
      subject: subject,
      client: client
    }
  end

  test "redirects to sign in page for unauthorized user", %{
    account: account,
    client: client,
    conn: conn
  } do
    assert live(conn, ~p"/#{account}/clients/#{client}") ==
             {:error,
              {:redirect,
               %{
                 to: ~p"/#{account}/sign_in",
                 flash: %{"error" => "You must log in to access this page."}
               }}}
  end

  test "renders not found error when client is deleted", %{
    account: account,
    client: client,
    identity: identity,
    conn: conn
  } do
    client = Fixtures.Clients.delete_client(client)

    assert_raise Web.LiveErrors.NotFoundError, fn ->
      conn
      |> authorize_conn(identity)
      |> live(~p"/#{account}/clients/#{client}")
    end
  end

  test "renders breadcrumbs item", %{
    account: account,
    client: client,
    identity: identity,
    conn: conn
  } do
    {:ok, _lv, html} =
      conn
      |> authorize_conn(identity)
      |> live(~p"/#{account}/clients/#{client}")

    assert item = Floki.find(html, "[aria-label='Breadcrumb']")
    breadcrumbs = String.trim(Floki.text(item))
    assert breadcrumbs =~ "Clients"
    assert breadcrumbs =~ client.name
  end

  test "renders client details", %{
    account: account,
    client: client,
    actor: actor,
    identity: identity,
    conn: conn
  } do
    {:ok, lv, _html} =
      conn
      |> authorize_conn(identity)
      |> live(~p"/#{account}/clients/#{client}")

    table =
      lv
      |> element("#client")
      |> render()
      |> vertical_table_to_map()

    assert table["identifier"] == client.id
    assert table["name"] == client.name
    assert table["owner"] =~ actor.name
    assert table["created"]
    assert table["last seen"]
    assert table["remote ipv4"] =~ to_string(client.ipv4)
    assert table["remote ipv6"] =~ to_string(client.ipv6)
    assert table["client version"] =~ client.last_seen_version
    assert table["user agent"] =~ client.last_seen_user_agent
  end

  test "renders client owner", %{
    account: account,
    client: client,
    identity: identity,
    conn: conn
  } do
    actor = Repo.preload(client, :actor).actor

    {:ok, lv, _html} =
      conn
      |> authorize_conn(identity)
      |> live(~p"/#{account}/clients/#{client}")

    assert lv
           |> element("#client")
           |> render()
           |> vertical_table_to_map()
           |> Map.fetch!("owner") =~ actor.name
  end

  test "allows editing clients", %{
    account: account,
    client: client,
    identity: identity,
    conn: conn
  } do
    {:ok, lv, _html} =
      conn
      |> authorize_conn(identity)
      |> live(~p"/#{account}/clients/#{client}")

    assert lv
           |> element("a", "Edit Client")
           |> render_click() ==
             {:error,
              {:live_redirect, %{to: ~p"/#{account}/clients/#{client}/edit", kind: :push}}}
  end

  test "allows deleting clients", %{
    account: account,
    client: client,
    identity: identity,
    conn: conn
  } do
    {:ok, lv, _html} =
      conn
      |> authorize_conn(identity)
      |> live(~p"/#{account}/clients/#{client}")

    assert lv
           |> element("button", "Delete Client")
           |> render_click() ==
             {:error, {:redirect, %{to: ~p"/#{account}/clients"}}}

    assert Repo.get(Domain.Clients.Client, client.id).deleted_at
  end
end
