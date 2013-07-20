Code.require_file "test_helper.exs", __DIR__

defmodule ExnfTest do
  use ExUnit.Case
  setup do
    config = [poll_interval: 5,strategy: :file,mode: :simple]
    Exnf.start_link(config)
    :ok
  end
  teardown do
     Exnf.stop
     :ok
  end
  test "loads config" do
    Exnf.stop
	  config = [poll_interval: 5,strategy: :file,mode: :simple]
    {result,pid} = Exnf.start_link(config)
    assert(:ok == result)
  end
  test "creates random node name" do
    result  = Exnf.rand_name
    assert(result != :"nonode@nohost")
  end
  test "assignes previous node name" do

  end
  test "sets ping interval" do

  end
  test "broadcasts events" do

  end
  test "announces down nodes" do

  end
  test "fences down nodes" do

  end
  test "cidr mode"  do

  end
  test "text file mode" do

  end
  test "s3 mode" do

  end
  test "sg mode" do

  end
end
