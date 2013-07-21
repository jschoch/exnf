defmodule Exnf.Strategy.RR do
	require Lager
  def do_find_nodes do
		case Exnf.get_config[:rr_name] do
			nil -> 
				Lager.error "No rr_name in config!" 
				[]
			rr_name -> 
				{:ok,msg} = :inet_res.getbyname(rr_name,:a)
				{_,_,_,_,_,addrs} = msg
				Enum.map(addrs,fn(addr) -> 
					tuple_to_list(addr) |> Enum.join "."
					end
					)
		end
  end
end