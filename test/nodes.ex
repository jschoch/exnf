Code.require_file "test_helper.exs", __DIR__

defmodule ExnfTest do
  use ExUnit.Case
  setup do
    :os.cmd('./exnf &')  
    :os.cmd('./exnf &')
    :os.cmd('./exnf &')
    :os.cmd('./exnf &')
    Exnf.start
    :ok
  end
  teardown do
    :timer.sleep(100)
    Exnf.shutdown_all
    :ok
  end

  test "node names make sense" do
    IO.puts inspect Exnf.list
  end
end
