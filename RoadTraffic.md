# Getting started

## Loading a table

The first step consists of connecting your GAMA world to an existing CityScope table.

In this example, we connect our world to a table called `cityscopejs_gama`. This sets up the `global` as well as all `brix` agents representing the cells of the interactive area of the grid. `brix` agents have a `name`, a `color`, a `height`, and more importantly a `type`, all coming from the table and its definitions. 

```java
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

experiment CityScope type: gui autorun: false{
	output {
		display map_mode type:opengl background:#black{	
			species brix aspect:base;
		}
	}
}
```

## People Agents

This second step illustrates how to obtain a random point inside each cell. We will also define some moving agent called people.


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
	parameter "Number of people agents" var: nb_people category: "People" ;

	output {
		display map_mode type:opengl background:#black{
			species brix aspect: base transparency: 0.5;
			species people aspect: base;
		}
	}
}
```