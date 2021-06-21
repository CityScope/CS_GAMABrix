/**
* Name: template
* Template for GAMABrix model that interfaces with a CityScope table.
* Author: crisjf
* GitHub: https://github.com/CityScope/CS_GAMABrix
*/


model template

import "GAMABrix.gaml"

global {
	string city_io_table<-"cityscopejs_gama";  
	geometry shape <- envelope(setup_cityio_world());
	bool listen  <- false;
	bool post_on <- false;
	
	init {
		do brix_init;
	}
}

experiment CityScope type: gui autorun:false{
	output {
		display map_mode type:opengl background:#black{	
			species brix aspect:base;
		}
	}
}
