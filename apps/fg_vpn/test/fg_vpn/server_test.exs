defmodule FgVpn.ServerTest do
  use ExUnit.Case, async: true
  alias FgVpn.{Config, Peer, Server}
  import FgVpn.CLI

  @empty %Config{}
  @single_peer %Config{peers: MapSet.new([%Peer{public_key: "test-pubkey"}])}

  describe "state" do
    setup %{stubbed_config: config} do
      test_pid = start_supervised!(Server)

      GenServer.cast(test_pid, {:set_config, config})

      on_exit(fn -> cli().teardown() end)

      %{test_pid: test_pid}
    end

    @tag stubbed_config: @empty
    test "generates new peer when requested", %{test_pid: test_pid} do
      send(test_pid, {:create_device, self()})

      assert_receive {:device_created, _, _, _, _}
      assert [_peer] = MapSet.to_list(:sys.get_state(test_pid).uncommitted_peers)
      assert [] = MapSet.to_list(:sys.get_state(test_pid).peers)
    end

    @tag stubbed_config: @single_peer
    test "removes peers from config when removed", %{test_pid: test_pid} do
      send(test_pid, {:remove_peer, "test-pubkey"})

      # XXX: Avoid sleeping
      Process.sleep(100)

      assert MapSet.to_list(:sys.get_state(test_pid).peers) == []
    end
  end
end
