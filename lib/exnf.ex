defmodule Exnf do
  use GenServer.Behaviour
  #use Appication.Behavior
  use Application.Behaviour
  require Lager
  def start(_type,_args) do
    start_link([ping_interval: 5,strategy: :file,mode: :default])
  end
  def start_link(config) do
    #rand_name
    nodes = [node, [created_at: "now"]]
    case config[:strategy] do
      :file -> Lager.debug "using :file strategy"
      :cidr -> Lager.debug "using :cidr strategy"
      _ -> Lager.error "Exnf.start_link: no strategy"
    end 
    case config[:node_name] do
      nil -> 
        Lager.debug "no node name in config, creating random name"
        assign_name 
      node_name -> 
        assign_name(node_name)
    end 
    master_name = "exnf_master@#{:net_adm.localhost}"  |> binary_to_atom
    case :net_adm.ping(master_name) do
      :pang ->
        Lager.info "Exnf.start_link: no master, assigning this node"
        config = ListDict.put(config,:node_name, master_name)
        assign_name(master_name)
      :pong ->
        Lager.debug "master node found on host!"
      doh ->
        Lager.error "Exnf.start_link: something terrible happened"
    end
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
  def get_config do
    :gen_server.call :exnf,:get_config
  end
  def handle_call(:get_config,_from,{config,nodes}) do
    {:reply,config,{config,nodes}}
  end
  def assign_name do
    rand_name
  end
  def assign_name(name) when is_atom(name) do
    :application.stop(:lager)
    :net_kernel.stop
    res = :net_kernel.start([name, :longnames])
    :application.start(:lager)
    Lager.debug("res was: #{inspect res}")
  end
  def assign_name(name) do
    Lager.error "Name must be an atom"
    rand_name
  end
  def rand_name do
    #:application(lager: :stop)Lager.stop
    :application.stop(:lager)
    :net_kernel.stop
    :random.seed(:erlang.now)
    node_name = "n#{:random.uniform(100000)}" |> binary_to_atom
    case :net_kernel.start([node_name, :longnames]) do
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
