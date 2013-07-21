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
    start_link([poll_interval: 200,strategy: :file,mode: :default])
  end
  def master_name do
    "exnf_master@#{:net_adm.localhost}"  |> binary_to_atom
  end
  def find_nodes do
    config = get_config
    case config[:strategy] do
      :file -> Lager.info "using :file strategy"
        import Exnf.Strategy.File
        do_find_nodes
        #use Exnf.Strategy.File
        #alias Exnf.Stategy.File.nodes
      :cidr -> Lager.info "using :cidr strategy"
        import Exnf.Strategy.Cidr
        do_find_nodes
      _ -> Lager.error "Exnf.start_link: no strategy"
    end 

  end
  def start_link(config) do
    case config[:node_name] do
      nil -> 
        Lager.info "no node name in config, creating random name"
        assign_name 
      node_name -> 
        assign_name(node_name)
    end 
    #master_name = "exnf_master@#{:net_adm.localhost}"  |> binary_to_atom
    case :net_adm.ping(master_name) do
      :pang ->
        Lager.info "Exnf.start_link: no master, assigning this node"
        config = ListDict.put(config,:node_name, master_name)
        assign_name(master_name)
      :pong ->
        Lager.info "master node found on host!"
      doh ->
        Lager.error "Exnf.start_link: something terrible happened"
    end
    nodes = Node.list
    connect_results = Enum.map(nodes,Node.connect(&1))
    Lager.info "connect results: #{inspect connect_results}"
    ret = :gen_server.start_link({:local,:exnf},__MODULE__,{config,nodes},[])
    :timer.sleep(1000)
    sp
    ret
  end
  def init(config) do
    Lager.info "Exnf starting up with config: #{inspect config}"
    {:ok, config}
  end
  
  def get_nodes do
    :gen_server.call :exnf, :get_nodes
  end 
  def handle_call(:get_nodes,_from,{config,nodes}) do
    {:reply,nodes,{config,nodes}}
  end
  def shutdown(node_name) do
    #Lager.info "shutting down #{node_name}" 
    stop_fn = fn -> Exnf.stop end
    #Node.spawn(node_name, stop_fn)
    :gen_server.call {:exnf, node_name}, :stop
  end
  def shutdown_all do
    nodes = get_nodes
    Lager.info "Shutting down nodes: #{inspect nodes}"
    Enum.map(nodes,fn(node) ->
      Lager.info "Attempting to shut down node: #{node}" 
      res = shutdown(node)
      Lager.info "result from shutdown was #{res}"
      end
      )
    Lager.info "Shutdown: sleeping"
    :timer.sleep(2000)
    :gen_server.call :exnf, :stop
  end
  def sp do
    start_loop_poll
  end
  def start_loop_poll do
    Lager.info "Exnf.start_loop_poll: #{inspect get_nodes}"
    :gen_server.cast :exnf, :loop_poll
  end
  def poll(poll_interval) do
    #Lager.info "Poll SPAWN: #{inspect self}"
    :timer.sleep(poll_interval)
    :gen_server.cast :exnf, :loop_poll
  end
  def handle_cast( :loop_poll, {config, nodes}) do
    new_nodes = Enum.uniq(nodes ++ Node.list)
    results = Enum.map(new_nodes,ping(&1,nodes))
    pi = config[:poll_interval]
    #Lager.info "nodes #{inspect nodes}\nconfig #{inspect config}\npi #{inspect pi}\nresults #{inspect results}"
    results = Enum.filter(results,fn({key,val}) -> key != :ignore end)
    if ((Enum.count(results)) > 0) do
      Lager.info "Node list was: #{inspect new_nodes}"
      :gen_server.cast(:exnf,{:updates,results}) 
    end
    if (is_number(pi)) do
      #Lager.info "Exnf.poll: sleeping for #{pi}"
      spawn(__MODULE__,:poll,[config[:poll_interval]])
    else
      Lager.info "Exnf.poll Exiting polling loop"
    end
    {:noreply,{config,new_nodes}}
  end
  def handle_cast({:updates,results},{config,nodes}) when results != [nil] do
    Lager.info "updates #{inspect results}" 
    reduced = Enum.reduce(results,[add: [], remove: [],ignore: []],fn({key,val},acc) -> ListDict.put(acc,key,[val|acc[key]]) end)
    Lager.info "reduced: #{inspect reduced}"
    spawn(__MODULE__,:do_updates,[reduced])
    {:noreply,{config,nodes}}
  end
  def do_updates(updates) when is_list(updates) do
    adds = updates[:add]
    Enum.map(adds,fn (node) -> add(node) end)
    removes = updates[:remove]
    Enum.map(removes,fn (node) -> remove(node) end)
    ignores = updates[:ignore] 
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
    Lager.info "Exnf.add #{inspect nodes}"
    {:reply,nodes,{config,nodes}}
  end
  def remove(node) do
    new_nodes = Enum.filter(get_nodes,&1 != node)
    :gen_server.call :exnf, {:update_nodes,new_nodes}
  end
  def handle_call({:update_nodes,new_nodes},_from,{config,nodes}) do
    {:reply,new_nodes,{config,new_nodes}}
  end
  def update_config(new_config) do
    :gen_server.call :exnf, {:update_config,new_config}
  end
  def handle_call({:update_config,new_config},_from,{config,nodes}) do
    {:reply,new_config,{new_config,nodes}}
  end
  def ping(node,nodes) do
     action = :ignore
     case :net_adm.ping(node) do
      :pang -> 
        if (node != master_name) do
          Lager.info "Exnf.ping: removing node #{inspect node}" 
          action =  :remove
        else
          Lager.info "master node appears down"
          action = :ignore
        end
      :pong -> unless node in nodes do
          Lager.info "Exnf.ping: adding node #{inspect node}"
          action = :add
        end
      :pong -> 
        Lager.info "Exnf.ping: pong ignoring #{inspect node}"
        action = :ignore
      doh -> Lager.error "something fucked up #{doh}"
    end
    #Lager.info "Ping: action : #{action} node #{node}"
    {action,node}

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
    :application.stop(:exlager)
    :net_kernel.stop
    res = :net_kernel.start([name, :longnames])
    :application.start(:exlager)
    Lager.info("res was: #{inspect res}")
  end
  def assign_name(name) do
    Lager.error "Name must be an atom"
    rand_name
  end
  def rand_name do
    :application.stop(:exlager)
    :net_kernel.stop
    :random.seed(:erlang.now)
    node_name = "n#{:random.uniform(100000)}" |> binary_to_atom
    case :net_kernel.start([node_name, :longnames]) do
      {:ok,_} -> 
        :application.start(:exlager)
        Lager.info "set node name to #{inspect node_name} #{inspect node}"
      doh -> 
        :application.start(:exlager)
        Lager.error "Exnf.rand_name: unable to set node name\n#{inspect doh}"
    end
    :application.start(:exlager)
    Lager.info "Node name set to: #{inspect node}"  
  end
end
