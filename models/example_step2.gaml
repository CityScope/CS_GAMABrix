/**
* Name: examplepeople
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
	
	int nb_people <- 100;
	list<brix> residential_cells;
	
	init {
		do brix_init;
		
		residential_cells <- brix where (each.type="Residential");
		create people number: nb_people {
			location <- any_location_in (one_of (residential_cells));
		}
	}
}

species people {
	rgb color <- #green ;

	aspect base {
		draw sphere(10) color: color border: color;
	}
}

experiment CityScope type: gui autorun:false{
	parameter "Number of people agents" var: nb_people category: "People" ;

	output {
		display map_mode type:opengl background:#black{
			species brix aspect: base transparency: 0.5;
			species people aspect: base;	
		}
	}
}


