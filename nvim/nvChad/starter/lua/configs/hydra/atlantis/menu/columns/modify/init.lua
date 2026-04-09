local node = require("configs.hydra.atlantis.menu.nodes")

-- Modify column menu
return function(runtime_ctx)
	return node.get_node_menu_spec(runtime_ctx)
end
