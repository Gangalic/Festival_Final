/***
* Name: NewModel
* Author: Catalin
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model NewModel

global {
	/** Insert the global definitions, variables and actions here */
	// guest variables
	int nb_guests <- 50 + rnd(10);
	int nb_types_guests <- 5;
	int guest_type_ratio <- int(nb_guests/nb_types_guests);
	int nb_stages <- 3;
	
	// stage variables
	list<string> music_genres <- ["country", "electro", "blues", "rock", "hip-hop", "pop", "jazz"];
	int show_duration_min <- 100;
	int show_duration_max <- 1000;
	
	
	init {
		create Dancer number: rnd(guest_type_ratio-1, guest_type_ratio+1) {
			self.guest_color <- #orange;
		}
		create Drunkard number: rnd(guest_type_ratio-1, guest_type_ratio+1) {
			self.guest_color <- #violet;
		}
		create Hippie number: rnd(guest_type_ratio-1, guest_type_ratio+1) {
			self.guest_color <- #green;
		}
		create Druggie number: rnd(guest_type_ratio-1, guest_type_ratio+1) {
			self.guest_color <- #blue;
		}
		create Newbie number: nb_guests - length(list(Dancer)) - length(list(Drunkard)) - length(list(Hippie)) - length(list(Druggie)) {
			self.guest_color <- #yellow;
		}
		create Stage number: nb_stages {
			self.location <- {rnd(25,75), rnd(25,75)};
		}
		// generating 4 bars, one in each corner of the festival
		create Bar {
			self.location <- {rnd(10,20), rnd(10,20)};
		}
		create Bar {
			self.location <- {rnd(10,20), rnd(80,90)};
		}
		create Bar {
			self.location <- {rnd(80,90), rnd(10,20)};
		}
		create Bar {
			self.location <- {rnd(80,90), rnd(80,90)};
		}
	}
	
}

/* ------------------------- Guests ---------------------- */
species Guest skills: [fipa, moving] {
	int alchool;
	int drugs;
	int dance;
	int talks;
	float happiness;
	
	int guest_size <- 1;
	rgb guest_color;
	Building target;
	
	// wander when nothing to do
	reflex wander when: target = nil {
		do wander bounds: circle(0.5);
	}
	
}

// always interested in partying
species Dancer parent: Guest {
	aspect default {
		draw sphere(guest_size) color: self.guest_color;
	}
}

// always interested in drinking
species Drunkard parent: Guest {
	aspect default {
		draw sphere(guest_size) color: self.guest_color;
	}
}

// always interested in alternative life style
species Hippie parent: Guest {
	aspect default {
		draw sphere(guest_size) color: self.guest_color;
	}
}

// always interested in taking drugs and having fun
species Druggie parent: Guest {
	aspect default {
		draw sphere(guest_size) color: self.guest_color;
	}
}

// interested in trying various things
species Newbie parent: Guest {
	aspect default {
		draw sphere(guest_size) color: self.guest_color;
	}
}

/* ------------------------- Buildings ---------------------- */
species Building skills: [fipa] {
	int build_size <- 4;
	rgb build_color;
	// saves the people actually at the place
	list<Guest> crowd;
	
}

// place where guests can dance
species Stage parent: Building {
	int start_time;
	int show_duration;
	string genre;
	int stage_size <- int(build_size*1.5);
	
	init {
		do set_utilities;
		write "\n" + self.name + " will start a concert of " + self.genre;
	}
	
	aspect default {
		draw circle(self.stage_size) color: #gray at: self.location;
		draw cone3D(build_size/2, self.stage_size) color: rnd_color(255) at: self.location;
	}
	
	//When the show is over, remove stage from the stages list and remove stage util from the guests and reset them 
	reflex shutdown_show when: time >= start_time + show_duration {
		write "\n" + self.name + " concert of " + self.genre + " has finished";	
		// anounce Guests about show end
		do start_conversation (to: list(agents of_generic_species Guest), protocol: 'fipa-propose', performative: 'cfp', contents: ['concert', 'stop']);
		
		// change location when concert finished
		self.location <- {rnd(25,75),rnd(25,75)};
		do set_utilities;
		write "\n" + self.name + " will start a concert of " + self.genre;
	}
	
	// resend calls to concert once in 20 to 50 simulations
	reflex resend_data when: int(time) mod rnd(20,50) = 0 {
		do start_conversation (to: list(agents of_generic_species Guest), protocol: 'fipa-propose', performative: 'cfp', 
			contents: ['concert', 'start', genre]);
	}
	
	
	action set_utilities {
		// empty the crowd
		self.crowd <- [];
		
		self.genre <- music_genres[rnd(length(music_genres) - 1)];
		
		// For how long the show will run
		start_time <- int(time);
		show_duration <- rnd(show_duration_min, show_duration_max);
		
		// announce through FIPA
		do start_conversation (to: list(agents of_generic_species Guest), protocol: 'fipa-propose', performative: 'cfp', 
			contents: ['concert', 'start', genre]);
	}
	
}

// place where gusts can drink
species Bar parent: Building {
	
	aspect default {
		draw square(build_size*2) color: #cyan at: self.location-{build_size,0};
		draw square(build_size*2) color: #cyan at: self.location+{build_size,0};
		draw cube(build_size) color: #blue at: self.location-{build_size*0.5,0};
		draw cube(build_size) color: #blue at: self.location+{build_size*0.5,0};
		
	}
}

experiment start_festival  type: gui {
	output
	{
		display main_display type: opengl
		{
			species Stage;
			species Bar;
			species Dancer;
			species Drunkard;
			species Druggie;
			species Hippie;
			species Newbie;
		}
	}
}
