defmodule Exnf do
  use GenServer.Behaviour
  require Lager
  def start_link(config) do
    rand_name
    strategy = config[:strategy] 
    nodes = [node, [created_at: "now"]]
    case strategy do
      :file -> Lager.debug "using :file strategy"
      :cidr -> Lager.debug "using :cidr strategy"
      _ -> Lager.error "Exnf.start_link: no strategy"
    end 
    :ok
    :gen_server.start_link({:local,:exnf},__MODULE__,{config,nodes},[])
  end
  def init({config,nodes}) do
    Lager.info "Exnf starting up with config: #{inspect config}"
    state = {config,nodes}
    {:ok, state}
  end
  
  def list do
    :gen_server.call :exnf, :stop
  end 
  def stop do
    :gen_server.call :exnf, :stop
  end
  def handle_call(:stop,_from,state) do
    Lager.info "Exnf shuttind down"
    {:stop, :normal, :shutdown_ok, state}
  end
  def search(nodes,frequency) do
    
  end
  def add(node) do

  end
  def remove(node) do

  end
  def ping(nodes) do

  end 
  def rand_name do
    #:application(lager: :stop)Lager.stop
    :application.stop(:lager)
    :net_kernel.stop
    :random.seed(:erlang.now)
    node_name = "n#{:random.uniform(100000)}" |> binary_to_atom
    case :net_kernel.start([node_name, :shortnames]) do
      {:ok,_} -> 
        :application.start(:lager)
        Lager.debug "set node name to #{node_name} #{node}"
      doh -> 
        :application.start(:lager)
        Lager.error "Exnf.rand_name: unable to set node name\n#{doh}"
    end
    :application.start(:lager)
    #Lager.start
    Lager.debug "Node name set to: #{node}"  
  end
end
