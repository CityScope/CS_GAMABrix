/**
* Name: example
* Based on the internal empty template. 
* Author: cristianjf
* Tags: 
*/


model example

import "GAMABrix.gaml"

global {
	string city_io_table<-"cityscopejs_gama";  
    geometry shape <- envelope(setup_cityio_world());
	bool listen  <- false;
	bool post_on <- false;
	
	init {

	}
}

experiment CityScope type: gui autorun:false{
	output {
		display map_mode type:opengl background:#black{	
			species brix aspect:base;
		}
	}
}
