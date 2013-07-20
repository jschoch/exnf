defmodule Exnf do
  use GenServer.Behaviour
  #use Appication.Behavior
  use Application.Behaviour
  require Lager
  def main(args) do
    start("?",[])
    sleep?
  end
  def sleep? do
    running_apps = :application.which_applications
    res = Enum.any?(running_apps,fn({name,_,_}) -> name == :exnf end)
    if (res) do
      :timer.sleep(100)
      sleep?
    end
  end
  def start do
    start("?",[])
  end
  def start(_type,_args) do
    start_link([ping_interval: 5,strategy: :file,mode: :default])
  end
  def start_link(config) do
    #rand_name
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
    nodes = Node.list
    connect_results = Enum.map(nodes,Node.connect(&1))
    Lager.debug "connect results: #{inspect connect_results}"
    :gen_server.start_link({:local,:exnf},__MODULE__,{config,nodes},[])
  end
  def init(config) do
    Lager.info "Exnf starting up with config: #{inspect config}"
    {:ok, config}
  end
  
  def list do
    :gen_server.call :exnf, :list
  end 
  def handle_call(:list,_from,{config,nodes}) do
    {:reply,nodes,{config,nodes}}
  end
  def shutdown(node_name) do
    #Lager.debug "shutting down #{node_name}" 
    stop_fn = fn -> Exnf.stop end
    #Node.spawn(node_name, stop_fn)
    :gen_server.call {:exnf, node_name}, :stop
  end
  def shutdown_all do
    nodes = list
    Lager.debug "Shutting down nodes: #{inspect nodes}"
    Enum.map(nodes,fn(node) ->
      Lager.info "Attempting to shut down node: #{node}" 
      res = shutdown(node)
      Lager.info "result from shutdown was #{res}"
      end
      )
    Lager.debug "Shutdown: sleeping"
    :timer.sleep(2000)
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
    :gen_server.call :exnf, {:add,node}
  end
  def handle_call({:add,node},_from,{config,nodes}) do
    nodes = [node | nodes]
    {:reply,nodes,{config,nodes}}
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
    Lager.debug "Node name set to: #{node}"  
  end
end
