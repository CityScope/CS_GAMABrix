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
	bool listen  <- true;
	bool post_on <- true;
		
	int nb_people <- 100;
	date starting_date <- date("2019-09-01-00-00-00");
	int min_work_start <- 6;
	int max_work_start <- 8;
	int min_work_end <- 16; 
	int max_work_end <- 20; 
	float min_speed <- 1.0 #km / #h;
	float max_speed <- 5.0 #km / #h; 
	
	init {
		do brix_init;
		
		list<brix> residential_cells <- brix where (each.type="Residential");
		list<brix> industrial_cells  <- brix where (each.type="Industrial");
    	create people number: nb_people {
			speed <- rnd(min_speed, max_speed);
			start_work <- rnd (min_work_start, max_work_start);
			end_work <- rnd(min_work_end, max_work_end);
			living_place  <- one_of(residential_cells) ;
			working_place <- one_of(industrial_cells) ;
			objective <- "resting";
			location <- any_location_in (living_place); 
		}
		
		create commute_distance;
	}

	
	action reInit {
		list<brix> residential_cells <- brix where  (each.type="Residential");
		list<brix> industrial_cells  <- brix where (each.type="Industrial");
		ask people {
			if (not (residential_cells contains self.living_place)) {
				self.living_place  <- one_of(residential_cells) ;
			}
			if (not (industrial_cells  contains self.working_place)) {
				self.working_place <- one_of(industrial_cells) ;
			}
		}
	}
}

species people parent: cityio_agent skills:[moving] {
	rgb color <- #green ;
	brix living_place <- nil ;
	brix working_place <- nil ;
	int start_work ;
	int end_work  ;
	string objective ; 
	point the_target <- nil ;
	
	bool is_visible<-true;
	    
	reflex time_to_work when: current_date.hour = start_work and objective = "resting"{
		objective <- "working" ;
		the_target <- any_location_in (working_place);
	}
	    
	reflex time_to_go_home when: current_date.hour = end_work and objective = "working"{
		objective <- "resting" ;
		the_target <- any_location_in (living_place); 
	} 
	 
	reflex move when: the_target != nil {
		do goto target: the_target; 
		if the_target = location {
			the_target <- nil ;
		}
	}
	
	aspect base {
		draw sphere(10) color: color border: color;
	}
}

species commute_distance parent: cityio_agent {
	string viz_type <- "bar";
	string indicator_type <- 'numeric';
	string indicator_name <- "Commute distance";
	
	bool is_numeric<-true;
	
	float avg_distance;
	float largest_distance;	
	float largest_possible_distance;
	
	init {
		list<float> pairwise_distances;
		ask brix {
			ask brix {
				pairwise_distances <+ distance_to(self,myself);
			}
			
		}
		largest_possible_distance<-max(pairwise_distances);
	}
	
	reflex update_numeric {
		list<float> brix_distances <- people collect distance_to(each.living_place,each.working_place);
		avg_distance     <- mean(brix_distances);
		largest_distance <- max(brix_distances);
		numeric_values<-[];
		numeric_values<+"Average commute distance"::avg_distance/largest_possible_distance;
		numeric_values<+"Longest commute distance"::largest_distance/largest_possible_distance;
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

