defmodule Exnf.Strategy.File do
	require Lager
  def do_find_nodes do
    #[:"foo",:"bar"]
    case File.read("hosts") do
   		{:ok,s} -> Jsonex.decode(s)
   		{:error,reason} -> 
   			Lager.error "Exnf.Strategy.File no file found" 
   			[]
    end
  end
end
