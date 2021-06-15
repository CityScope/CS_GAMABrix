# Getting started

This tutorial will follow the famous [Road Traffic](https://gama-platform.github.io/wiki/RoadTrafficModel) model. Since we are interested in seeting up this model in a CityScope table, we will not be loading any shapefiles but will instead use `GAMABrix` to setup our world as a copy of the interactive area in a given CityScope table. If you are new to GAMA, we recommend you complete [the Road Traffic Model tutorial](https://gama-platform.github.io/wiki/RoadTrafficModel), before returning to this tutorial.

First, create a table [here](https://cityscope.media.mit.edu/CS_cityscopeJS/) or choose an existing table. Take note of your table name. For this tutorial, make sure that your table has the types `Residential` and `Industrial` to simulate agents commuting from work to home and viceversa.

## Step 1: Loading a table

Once your table has been created, go ahead and connect your GAMA world to your table.

First, import the `GAMABrix` model by adding the following import right before your `global` definition:

```java
import "GAMABrix.gaml"
```

Next, we connect our world to a table called `cityscopejs_gama` by defining the table name in the global and by using this table to define the shape of the world:

```java
string city_io_table<-"cityscopejs_gama";  
geometry shape <- envelope(setup_cityio_world());
```

In the `global`, start by setting `bool listen <- false;` to ensure that your model is not in listen mode. We will discuss listen mode at the end of the tutorial. Set `bool post_on <- false;` as well while debugging until you are ready to start posting indicators to CityIO.

Finally, in the `global` init we call the action `brix_init`. This action uses the information from the CityScope grid to create `brix` agents representing the cells of the interactive area of the grid. `brix` agents have a `name`, a `color`, a `height`, and more importantly a `type`, all coming from the table and its definitions. 

The following example sets up the CitySope world and displays all agents of the `brix` species with their `base` aspect.

```java
model example

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

experiment CityScope type: gui autorun: false{
	output {
		display map_mode type:opengl background:#black{	
			species brix aspect:base;
		}
	}
}
```

## Step 1: People Agents

This second step, creates a series of `people` agents and assigns them to a random location in a `Residential` `brix` cell. This is why it was important that your table had `Residential` cells defined. 

First, we define `people` species and give them an aspect to be visualized. Since the default visualization of CityScope is three dimensional, we set the aspect of `people` as spheres.

```java
species people {
	rgb color <- #green ;

	aspect base {
		draw sphere(10) color: color border: color;
	}
}
```

Next, we define in our `global` the number of people `nb_people` as an integer, and create that many people agents and locate them in a residential cell. The global `init` then becomes:

```java
init {
	list<brix> residential_cells <- brix where (each.type="Residential");
	create people number: nb_people {
		location <- any_location_in (one_of (residential_cells));
	}
}
```

Finally, we add `people` to the expriment output using their `base` aspect we have defined. We also add a bit of transparency to the `brix` agents so that we can still see the `people` even if the buildings become very tall. The experiment `output` becomes:

```java
output {
	display map_mode type:opengl background:#black{
		species brix aspect: base transparency: 0.5;
		species people aspect: base;
	}
}
```

Putting it all together:

```java
model example

import "GAMABrix.gaml"

global {
	string city_io_table<-"cityscopejs_gama";  
	geometry shape <- envelope(setup_cityio_world());
	bool listen  <- false;
	bool post_on <- false;
	
	int nb_people <- 100;
	
	init {
		do brix_init;
		list<brix> residential_cells <- brix where (each.type="Residential");
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
	output {
		display map_mode type:opengl background:#black{
			species brix aspect: base transparency: 0.5;
			species people aspect: base;
		}
	}
}
```

## Step 3: Movement of people

The third step is to let the people move. Ideally, you would complement the table data with a shapefile with the road network. For now, we will assume that `people` agents can move freely on the grid. 

First, we import the `moving` skill for people agents in order to use the `goto` action. If you want to learn more about skills, follow the original tutorial [here](https://gama-platform.github.io/wiki/RoadTrafficModel_step3).

```java
species people skills: [moving] {
    ...
}
```

Then, we add new attributes to the people agents: `living_place`, `working_place`, `start_work`, `end_work` and `objective`. These attributes will help us simulate a typical day of commuting. In addition, we will create a `the_target` variable that will represent the point toward which the agent is currently moving.

We also create two reflexes, `time_to_go_home` and `time_to_work` that update the `objective` of each agent and its `the_target`. Finally, we define a reflex that allows the agent to `move`, that will only get triggered when `the_target != nil`. Here is where we use the `goto` action part of the `moving` skill. The key part of this action is:

```java
do goto target: the_target;
```

If we had a road network, we would load the road network into a variable called `the_graph` and ask agents to move through the road network by doing:

```java
do goto target: the_target on: the_graph;
```

The final definition of the `people` species is:


```java
species people skills:[moving] {
	rgb color <- #green ;
	brix living_place <- nil ;
	brix working_place <- nil ;
	int start_work ;
	int end_work  ;
	string objective ; 
	point the_target <- nil ;

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
```

After we have modified our `people` agents, we modify the `global` to add several parameters of the simulation: `min_work_start`, `max_work_start`, `min_work_end`, `max_work_end`, `min_speed` and `max_speed`. If we are using a road network, we also define `the_graph` here. In addition, we set the starting date and time to midnight.

```java
global {
	...
	date starting_date <- date("2019-09-01-00-00-00");
	int min_work_start <- 6;
	int max_work_start <- 8;
	int min_work_end <- 16; 
	int max_work_end <- 20; 
	float min_speed <- 1.0 #km / #h;
	float max_speed <- 5.0 #km / #h; 
	...
}
```

If we were using a shapefile with roads for the area where the table is located, we would create `the_graph` in the global init. For more information on this, follow the original tutorial [here](https://gama-platform.github.io/wiki/RoadTrafficModel_step3).

Finally, we setup the `init` in `global`. As before, the `init` starts by calling `brix_init` and then selects all `Residential` and `Industrial` cells to assign the work and home location of each person. 

```java
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
}
```

There is one issue with this init. When a cell is changed in the front end, the type of each `brix` agent might change. A residential cell might become a park, and the agent that was living there might have to relocate. We must define an additional `action` as part of the global called `reInit`. `GAMABrix` will run this action right after every grid update. In this case, our `reInit` action will start by selecting all `Residential` and `Industrial` cells and checking for every person if their home and workplace still is part of the set of `Residential` and `Industrial` cells. If not, it will reassign them to another place. 

```java
action reInit {
	list<brix> residential_cells <- brix where (each.type="Residential");
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
```

In this simple model, if new housing is added, people will not always flock there. They will only change their place of work and home when they disappear.

The full model looks as follows:

```java
model example

import "GAMABrix.gaml"

global {
	string city_io_table<-"cityscopejs_gama";  
	geometry shape <- envelope(setup_cityio_world());
	bool listen  <- false;
	bool post_on <- false;
	
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

species people skills:[moving] {
	rgb color <- #green ;
	brix living_place <- nil ;
	brix working_place <- nil ;
	int start_work ;
	int end_work  ;
	string objective ; 
	point the_target <- nil ;
	    
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

experiment CityScope type: gui autorun:false{
	parameter "Number of people agents" var: nb_people category: "People" ;

	output {
		display map_mode type:opengl background:#black{
			species brix aspect: base transparency: 0.5;
			species people aspect: base;	
		}
	}
}

```

## Step 4: Sending data to CityIO

In this section we will deviate from the original Road Traffic model, which goes much deeper into simulating road congestion. We will illustrate how to send the information from the agents to CityIO.

The first step, is to set `listen <- true;`. Listen mode is a bit different from the simulation you've been working with so far. When in listen mode, the simulation will run for one full day and post all that information to CityIO. The model will then remain idle until a grid update happens. Think about listen mode as recording a movie and sending it to someone else.

Which agents to record? To flag the agents that will be recorded, we modify the `species` definition to make it a `subspecies` of the `cityio_agent` species. By doing this, `GAMABrix` will interpret that these agents need to be tracked because they contain important information that needs to be posted to the table. To post their location, set `bool is_visible<-true;`:

```java
species people parent: cityio_agent skills:[moving] {
	bool is_visible<-true;
	...
}
```

With these simple modifications, the final model becomes:

```java
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

experiment CityScope type: gui autorun:false{
	parameter "Number of people agents" var: nb_people category: "People" ;

	output {
		display map_mode type:opengl background:#black{
			species brix aspect: base transparency: 0.5;
			species people aspect: base;	
		}
	}
}
```

## Step 5: Creating observers

For most use cases, users will want to post summary statistics about the table or about the agents to cityIO to be displayed in the front end. These indicators can be displayed as heatmaps, as part of a bar chart or as variables in the radar plot. In order to build these `indicators`, we need to build agents that will act as `observers` by reporting information to `cityIO`. Here, we will report the total commuting distance that all agents follows from home to work and back. We will display this information as a bar in the bar chart.







## Step 6: Headless mode

The final step in deploying a GAMA model to CityScope is to run it in a headless mode. This section will describe the steps needed to accomplish this. 







