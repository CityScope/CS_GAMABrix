# Getting started

This tutorial will follow the famous [Road Traffic](https://gama-platform.github.io/wiki/RoadTrafficModel) model. Since we are interested in seeting up this model in a CityScope table, we will not be loading any shapefiles but will instead use `GAMABrix` to setup our world as a copy of the interactive area in a given CityScope table. If you are new to GAMA, we recommend you complete [the Road Traffic Model tutorial](https://gama-platform.github.io/wiki/RoadTrafficModel), before returning to this tutorial.

First, create a table [here](https://cityscope.media.mit.edu/CS_cityscopeJS/) or choose an existing table. Take note of your table name. For this tutorial, make sure that your table has the types `Residential` and `Industrial` to simulate agents commuting from work to home and viceversa.

## Step 1: Loading a table

Once your table has been created, go ahead and connect your GAMA world to your table.

First, clone or fork the [GAMABrix](https://github.com/CityScope/CS_GAMABrix) repo and open the `template.gaml`. We recomend starting from this model.

The first line of the templae imports the `GAMABrix` model by adding the following import right before your `global` definition:

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

## Step 2: People Agents

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

For most use cases, users will want to post summary statistics about the table or about the agents to cityIO to be displayed in the front end. These indicators can be displayed as heatmaps, as part of a bar chart, or as variables in the radar plot. In order to build these `indicators`, we need to build agents that will act as `observers` by reporting information to `cityIO`. 

The simplest `indicator` is a `numeric` indicator that that collects information from the agents and reports a single number to CityIO. To create a `numeric` indicator, you can use the `cityio_numeric_indicator` species already included in `GAMABrix` and create an agent that belongs to this species. The important parameter is `indicator_value` which is a string that will be evaluated by GAMA at initialization. When in `listen` mode, this function will be evaluted everytime there is a table change. 

```java
create cityio_numeric_indicator with: (viz_type:"bar",indicator_name: "Average commute distance", indicator_value: "mean(people collect distance_to(each.living_place,each.working_place))");
```

This syntax works great for simple `numeric` indicators, but it is a bit restrictive. In some cases, we might want to build a more complex indicator that relies on more complex calculations. For example, we might want to report multiple statistics, or we might want to calculate commute distance over a road network, or we might have a need for an indicator that updates its value via a `reflex` instead of calculating everything at `init`. If this is the case, we need to define our own species of `numeric` indicators as a subspecies of the `cityio_agent`. The example below implements the exact same indicator as before, but defining our own species called `cityio_numeric_indicator`:

```java
species commute_distance parent: cityio_agent {
	string viz_type <- "bar";
	string indicator_type <- "numeric";
	string indicator_name <- "Average commute distance";
	
	bool is_numeric<-true;
	float avg_distance;	
	
	action calculate_numeric {
		avg_distance <- mean(people collect distance_to(each.living_place,each.working_place));
		numeric_values<-[];
		numeric_values<+indicator_name::avg_distance;
	}
}
```

The key is to update the `numeric_values` variable. This variable is a map between strings and floats, where the strings are the names of the indicator and the floats its values. Here, we do it through `calculate_numeric` action. By naming our main action this way, we tell `GAMABrix` that this needs to run every time the table changes. We could define any reflex or set of actions we wanted, as long as they update the `numeric_values` variable.  

To make this work, we need to create this agent in the global `init`:

```java
create commute_distance;
```

Until now, all examples have returned a single value for the numeric indicator. The example below extends this by creating an indicator that reports both the average commute distance and the total commute distance. The example below also normalizes both values using a normalization factor calculated in the `global` `init` of the species, ensuring the reported indicators are between 0 and 1. This illustrates how defining a subclass gives much more flexibility.

In the global `init`:

```java
init {
	do brix_init;
	
	residential_cells <- brix where (each.type="Residential");
	industrial_cells  <- brix where (each.type="Industrial");
	largest_possible_distance <- calculate_normalization();
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
	ask brix {
		if (self.type='Residential') {
			create work_distance with: (location:self.location);
		}
	}
	ask brix {
		if (self.type='Industrial') {
			create home_distance with: (location:self.location);
		}
	}
}

float calculate_normalization {
	list<float> pairwise_distances;
	ask residential_cells {
		ask industrial_cells {
			pairwise_distances <+ distance_to(self,myself);
		}
	}
	largest_possible_distance <- max(pairwise_distances);
	return largest_possible_distance;
}

action reInit {
	residential_cells <- brix where (each.type="Residential");
	industrial_cells  <- brix where (each.type="Industrial");
	largest_possible_distance <- calculate_normalization();
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

The advantage of defining `largest_possible_distance` as a global variable is that we can use it to normalize all indicators. The `commute_distance` indicator becomes:

```java
species commute_distance parent: cityio_agent {
	string viz_type <- "bar";
	string indicator_type <- 'numeric';
	string indicator_name <- "Commute distance";
	
	bool is_numeric<-true;
	bool re_init<-true;
	
	float avg_distance;
	float largest_distance;	
	
	action calculate_numeric {
		list<float> brix_distances <- people collect distance_to(each.living_place,each.working_place);
		avg_distance     <- mean(brix_distances);
		largest_distance <- max(brix_distances);
		numeric_values<-[];
		numeric_values<+"Average commute distance"::avg_distance/largest_possible_distance;
		numeric_values<+"Longest commute distance"::largest_distance/largest_possible_distance;
	}
}
```

Finally, we will add two `heatmap` indicators. Heatmap indicators follow a similar logic as numeric indicators, with the difference that agents that report heatmap information need to be placed on the grid (they need to have a location). These agents then report information back to CityIO, and because these agents have a location in the grid, the information they report is spatial. For example, to construct an agent that reports its distance to the closest industrial cell we define the `calculate_heatmap` action that updates `heatmap_values` (as opposed to `numeric_values`):

```java
species work_distance parent: cityio_agent {
	bool is_heatmap<-true;
	string indicator_type<-"heatmap";
	string indicator_name<-"Work distance";
		
	action calculate_heatmap {
		float closest_workplace<- distance_to(closest_to(industrial_cells, self),self);
		heatmap_values<-[];
		heatmap_values<+ "closest workplace"::closest_workplace/largest_possible_distance;
	}
}
```

Where do we place these agents? In theory, they can be placed anywhere in the grid. But if we are interested in showing the distance to the closest workplace of every residential cell, we will place these agents in the center of residential cells. In the `global` `init` we create these agents as:

```java
ask brix {
	if (self.type='Residential') {
		create work_distance with: (location:self.location);
	}
}
```

In a similar way, we might be interested in the location of housing relative to workplaces. We create another species that will report this information, and place agents of this species in the center of Industrial cells. These two species of heatmap agents will be translated into two heatmap layers when visualized in the front end.

```java
species home_distance parent: cityio_agent {
	bool is_heatmap<-true;
	string indicator_type<-"heatmap";
	string indicator_name<-"Home distance";
		
	action calculate_heatmap {
		float closest_residential<- distance_to(closest_to(residential_cells, self),self);
		heatmap_values<-[];
		heatmap_values<+ "closest residential"::closest_residential/largest_possible_distance;
	}
}
```

Just as with `numeric` indicators, if we ever have a need to define a `heatmap` indicator that updated every time step (counting traffic, for example), we can define a `reflex` that updates `heatmap_values`. `heatmap_values` is a map between strings and floats with each string being the name of the layer to be displayed. In this example, we have separated the distance to work and distance to home layers, but you can think about one species of agents reporting multiple values to CityIO. 

The final example, with both `numeric` and `heatmap` indicators looks like:

```java
model example

import "GAMABrix.gaml"

global {
	string city_io_table<-"cityscopejs_gama";  
	geometry shape <- envelope(setup_cityio_world());
	bool listen  <- true;
	bool post_on <- true;
		
	int nb_people <- 100;
	list<brix> residential_cells;
	list<brix> industrial_cells;
	date starting_date <- date("2019-09-01-00-00-00");
	int min_work_start <- 6;
	int max_work_start <- 8;
	int min_work_end <- 16; 
	int max_work_end <- 20; 
	float min_speed <- 1.0 #km / #h;
	float max_speed <- 5.0 #km / #h; 
	float largest_possible_distance;
	
	init {
		do brix_init;
		
		residential_cells <- brix where (each.type="Residential");
		industrial_cells  <- brix where (each.type="Industrial");
		largest_possible_distance <- calculate_normalization();
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
		ask brix {
			if (self.type='Residential') {
				create work_distance with: (location:self.location);
			}
			if (self.type='Industrial') {
				create home_distance with: (location:self.location);
			}
		}
	}

	float calculate_normalization {
		list<float> pairwise_distances;
		ask residential_cells {
			ask industrial_cells {
				pairwise_distances <+ distance_to(self,myself);
			}
		}
		largest_possible_distance <- max(pairwise_distances);
		return largest_possible_distance;
	}
	
	
	
	action reInit {
		residential_cells <- brix where (each.type="Residential");
		industrial_cells  <- brix where (each.type="Industrial");
		largest_possible_distance <- calculate_normalization();
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
	bool re_init<-true;
	
	float avg_distance;
	float largest_distance;	
		
	action calculate_numeric {
		list<float> brix_distances <- people collect distance_to(each.living_place,each.working_place);
		avg_distance     <- mean(brix_distances);
		largest_distance <- max(brix_distances);
		numeric_values<-[];
		numeric_values<+"Average commute distance"::avg_distance/largest_possible_distance;
		numeric_values<+"Longest commute distance"::largest_distance/largest_possible_distance;
	}
}

species work_distance parent: cityio_agent {
	bool is_heatmap<-true;
	string indicator_type<-"heatmap";
	string indicator_name<-"Work distance";
		
	action calculate_heatmap {
		float closest_workplace<- distance_to(closest_to(industrial_cells, self),self);
		heatmap_values<-[];
		heatmap_values<+ "closest workplace"::closest_workplace/largest_possible_distance;
	}
}

species home_distance parent: cityio_agent {
	bool is_heatmap<-true;
	string indicator_type<-"heatmap";
	string indicator_name<-"Home distance";
		
	action calculate_heatmap {
		float closest_residential<- distance_to(closest_to(residential_cells, self),self);
		heatmap_values<-[];
		heatmap_values<+ "closest residential"::closest_residential/largest_possible_distance;
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


## Step 6: Headless mode

The final step in deploying a GAMA model to CityScope is to run it in a headless mode. This section will describe the steps needed to accomplish this. 

Let's say you finished writing your model and are ready to leave it running forever (in a server where you have ssh access, for example). 

We highly recommend using a docker container to run headless GAMA on a server. This will take care of compatibility issues between platforms. 

First, pull the image from dockerhub. This step only needs to be performed once per server. We will be using [this image](https://hub.docker.com/r/gamaplatform/gama).
```java
> docker pull gamaplatform/gama
```

Second, we will build the `xml` file with the model meta parameters. You will only need to do this once for each model. Ensure you model directory (the folder that contains models, results, etc.) contains a `headless` folder. If you built your repo by forking [GAMABrix](https://github.com/CityScope/CS_GAMABrix) this folder should already be there. Then run the following command editing the name of your gama file (`model_file.gaml`) where needed:
```java
> docker run --rm -v "$(pwd)":/usr/lib/gama/headless/my_model gamaplatform/gama -xml CityScopeHeadless my_model/models/[model_file.gaml] my_model/headless/myHeadlessModel.xml
```

This creates a file called `myHeadlessModel.xml` in your `headless` folder. If you know how to edit this file, feel free to modify it now. For more information about this file, check the [documentation](https://gama-platform.github.io/wiki/Headless). Please note that by default the simulation will only run 1000 steps. If you wish to change this, edit the `xml` and change the `finalStep` property to a higher number or just delete if you wish the model to run continuosly.

Finally, we will run this model inside a container. This final step is the only step you will repeat when you modify your model. Run the following command, again from your model directory:
```java
> docker run --rm -v "$(pwd)":/usr/lib/gama/headless/my_model gamaplatform/gama my_model/headless/myHeadlessModel.xml my_model/results/
```

