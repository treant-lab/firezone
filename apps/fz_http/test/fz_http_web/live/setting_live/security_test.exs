defmodule FzHttpWeb.SettingLive.SecurityTest do
  use FzHttpWeb.ConnCase, async: true

  alias FzHttp.Configurations
  alias FzHttpWeb.SettingLive.Security
  import FzHttp.SAMLIdentityProviderFixtures

  describe "authenticated mount" do
    test "loads the active sessions table", %{admin_conn: conn} do
      path = ~p"/settings/security"
      {:ok, _view, html} = live(conn, path)

      assert html =~ "<h4 class=\"title is-4\">Authentication</h4>"
    end

    test "selects the chosen option", %{admin_conn: conn} do
      path = ~p"/settings/security"
      {:ok, _view, html} = live(conn, path)
      assert html =~ ~s|<option selected="selected" value="0">Never</option>|

      Configurations.get_configuration!()
      |> Configurations.update_configuration(%{vpn_session_duration: 3_600})

      {:ok, _view, html} = live(conn, path)
      assert html =~ ~s|<option selected="selected" value="3600">Every Hour</option>|
    end
  end

  describe "unauthenticated mount" do
    test "redirects to not authorized", %{unauthed_conn: conn} do
      path = ~p"/settings/security"
      expected_path = ~p"/"

      assert {:error, {:redirect, %{to: ^expected_path}}} = live(conn, path)
    end
  end

  describe "session_duration_options/0" do
    @expected_durations [
      Never: 0,
      Once: 2_147_483_647,
      "Every Hour": 3_600,
      "Every Day": 86_400,
      "Every Week": 604_800,
      "Every 30 Days": 2_592_000,
      "Every 90 Days": 7_776_000
    ]

    test "displays the correct session duration integers" do
      assert Security.session_duration_options() == @expected_durations
    end
  end

  describe "toggles" do
    import FzHttp.ConfigurationsFixtures

    setup %{conf_key: key, conf_val: val} do
      FzHttp.Configurations.put!(key, val)
      {:ok, path: ~p"/settings/security"}
    end

    for {key, val} <- [
          local_auth_enabled: true,
          allow_unprivileged_device_management: true,
          allow_unprivileged_device_configuration: true,
          disable_vpn_on_oidc_error: true
        ] do
      @tag conf_key: key, conf_val: val
      test "toggle #{key} when value in db is true", %{admin_conn: conn, path: path} do
        {:ok, view, _html} = live(conn, path)
        html = view |> element("input[phx-value-config=#{unquote(key)}}]") |> render()
        assert html =~ "checked"

        view |> element("input[phx-value-config=#{unquote(key)}]") |> render_click()
        assert FzHttp.Configurations.get!(unquote(key)) == false
      end
    end

    for {key, val} <- [
          local_auth_enabled: nil,
          allow_unprivileged_device_management: nil,
          allow_unprivileged_device_configuration: nil,
          disable_vpn_on_oidc_error: nil
        ] do
      @tag conf_key: key, conf_val: val
      test "toggle #{key} when value in db is nil", %{admin_conn: conn, path: path} do
        {:ok, view, _html} = live(conn, path)
        html = view |> element("input[phx-value-config=#{unquote(key)}]") |> render()
        refute html =~ "checked"

        view |> element("input[phx-value-config=#{unquote(key)}]") |> render_click()
        assert FzHttp.Configurations.get!(unquote(key)) == true
      end
    end
  end

  describe "oidc configuration" do
    import FzHttp.ConfigurationsFixtures

    setup %{admin_conn: conn} do
      configuration(%{
        openid_connect_providers: [
          %{
            "id" => "test",
            "label" => "test123",
            "client_id" => "foo",
            "client_secret" => "bar",
            "discovery_document_uri" =>
              "https://common.auth0.com/.well-known/openid-configuration"
          }
        ],
        saml_identity_providers: []
      })

      path = ~p"/settings/security"
      {:ok, view, _html} = live(conn, path)
      [view: view]
    end

    test "click add button", %{view: view} do
      html =
        view
        |> element("a", "Add OpenID Connect Provider")
        |> render_click()

      assert html =~ ~s|<p class="modal-card-title">OIDC Configuration</p>|
    end

    test "click edit button", %{view: view} do
      html =
        view
        |> element("a", "Edit")
        |> render_click()

      assert html =~ ~s|<p class="modal-card-title">OIDC Configuration</p>|
      assert html =~ ~s|value="test123"|
    end

    test "validate", %{view: view} do
      view
      |> element("a", "Edit")
      |> render_click()

      return =
        view
        |> form("#oidc-form")
        |> render_submit(%{"label" => "updated"})

      assert {:error, {:redirect, _}} = return

      assert FzHttp.Configurations.get!(:openid_connect_providers) == [
               %FzHttp.Configurations.Configuration.OpenIDConnectProvider{
                 id: "test",
                 label: "test123",
                 scope: "openid email profile",
                 response_type: "code",
                 client_id: "foo",
                 client_secret: "bar",
                 discovery_document_uri:
                   "https://common.auth0.com/.well-known/openid-configuration",
                 redirect_uri: nil,
                 auto_create_users: true
               }
             ]
    end

    test "delete", %{view: view} do
      view
      |> element("button", "Delete")
      |> render_click()

      assert FzHttp.Configurations.get!(:openid_connect_providers) == []
    end
  end

  describe "saml configuration" do
    import FzHttp.ConfigurationsFixtures

    setup %{admin_conn: conn} do
      # Security views use the DB config, not cached config, so update DB here for testing
      configuration(%{
        openid_connect_providers: [],
        saml_identity_providers: [saml_attrs()]
      })

      path = ~p"/settings/security"
      {:ok, view, _html} = live(conn, path)
      [view: view]
    end

    test "click add button", %{view: view} do
      html =
        view
        |> element("a", "Add SAML Identity Provider")
        |> render_click()

      assert html =~ ~s|<p class="modal-card-title">SAML Configuration</p>|

      html =
        view
        |> form("#saml-form", %{
          saml_identity_provider: %{
            metadata: "XXX",
            label: ""
          }
        })
        |> render_submit()

      assert html =~ "{:fatal, {:expected_element_start_tag,"
      assert html =~ "can&#39;t be blank"

      attrs = saml_attrs()

      return =
        view
        |> form("#saml-form", %{
          saml_identity_provider: %{
            id: "FAKEID",
            metadata: attrs["metadata"],
            label: "FOO"
          }
        })
        |> render_submit()

      assert {:error, {:redirect, _}} = return

      saml_identity_providers = FzHttp.Configurations.get!(:saml_identity_providers)

      assert length(saml_identity_providers) == 2

      assert %FzHttp.Configurations.Configuration.SAMLIdentityProvider{
               auto_create_users: true,
               # XXX this field would be nil if we don't "guess" the url when we load the record in StartServer
               base_url: "https://localhost/auth/saml",
               id: "FAKEID",
               label: "FOO",
               metadata: attrs["metadata"],
               sign_metadata: true,
               sign_requests: true,
               signed_assertion_in_resp: true,
               signed_envelopes_in_resp: true
             } in saml_identity_providers
    end

    test "edit", %{view: view} do
      html =
        view
        |> element("a", "Edit")
        |> render_click()

      assert html =~ ~s|<p class="modal-card-title">SAML Configuration</p>|
      assert html =~ ~s|entityID=&quot;http://localhost:8080/realms/firezone|

      html =
        view
        |> form("#saml-form", %{
          saml_identity_provider: %{
            label: "just-changed"
          }
        })
        |> render_submit()

      assert html =~ "value=\"just-changed\""

      # XXX this test fails, figure out why
      # assert [saml_identity_provider] = FzHttp.Configurations.get!(:saml_identity_providers)
      # assert saml_identity_provider.label == "changed"
    end

    test "validate", %{view: view} do
      attrs = saml_attrs()

      view
      |> element("a", "Edit")
      |> render_click()

      html =
        view
        |> element("#saml-form")
        |> render_submit(%{"metadata" => "updated"})

      # stays on the modal
      assert html =~ ~s|<p class="modal-card-title">SAML Configuration</p>|

      assert FzHttp.Configurations.get!(:saml_identity_providers) == [
               %FzHttp.Configurations.Configuration.SAMLIdentityProvider{
                 auto_create_users: true,
                 base_url: nil,
                 id: attrs["id"],
                 label: attrs["label"],
                 metadata: attrs["metadata"],
                 sign_metadata: true,
                 sign_requests: true,
                 signed_assertion_in_resp: true,
                 signed_envelopes_in_resp: true
               }
             ]
    end

    test "delete", %{view: view} do
      view
      |> element("button", "Delete")
      |> render_click()

      assert FzHttp.Configurations.get!(:saml_identity_providers) == []
    end
  end
end
