/***
* Name: Festival 
* Author: Catalin, Guilherme
* Description: A full festival where guests interact among each others and gain new attributes
***/

model NewModel

global {
	/** Insert the global definitions, variables and actions here */
	// guest variables
	int nb_guests <- 50 + rnd(10);
	int nb_types_guests <- 5;
	int guest_type_ratio <- int(nb_guests/nb_types_guests);
	int nb_stages <- 3;
	
	// attribute ranges
	int low_min <- 0;
	int low_max <- 29;
	int med_min <- 30;
	int med_max <- 59;
	int high_min <- 60;
	int high_max <- 100;
	int attr_change_min <- 1;
	int attr_change_max <- 3;
	
	// stage variables
	list<string> music_genres <- ["country", "electro", "blues"];
	int show_duration_min <- 300;
	int show_duration_max <- 500;
	
	float dancer_avg_hap;
	float drunkard_avg_hap;
	float hippie_avg_hap;
	float druggie_avg_hap;
	float newbie_avg_hap;
	
	init {
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
		create Dancer number: rnd(guest_type_ratio-1, guest_type_ratio+1) {
			// setting the initial attributes that define the type of guest
			self.guest_color <- #orange;
			alchool <- rnd(med_min, med_max);
			drugs <- rnd(low_min, low_max);
			dance <- rnd(high_min, high_max);
		}
		create Drunkard number: rnd(guest_type_ratio-1, guest_type_ratio+1) {
			// setting the initial attributes that define the type of guest
			self.guest_color <- #violet;
			alchool <- rnd(high_min, high_max);
			drugs <- rnd(low_min, low_max);
			dance <- rnd(low_min, low_max);
		}
		create Hippie number: rnd(guest_type_ratio-1, guest_type_ratio+1) {
			// setting the initial attributes that define the type of guest
			self.guest_color <- #green;
			alchool <- rnd(low_min, low_max);
			drugs <- rnd(med_min, med_max);
			dance <- rnd(med_min, med_max);
		}
		create Druggie number: rnd(guest_type_ratio-1, guest_type_ratio+1) {
			// setting the initial attributes that define the type of guest
			self.guest_color <- #blue;
			alchool <- rnd(low_min, low_max);
			drugs <- rnd(high_min, high_max);
			dance <- rnd(med_min, med_max);
		}
		create Newbie number: nb_guests - length(list(Dancer)) - length(list(Drunkard)) - length(list(Hippie)) - length(list(Druggie)) {
			// setting the initial attributes that define the type of guest
			self.guest_color <- #yellow;
			alchool <- rnd(low_min, low_max);
			drugs <- rnd(low_min, low_max);
			dance <- rnd(low_min, low_max);
		}
		
		write "Dancers: " + length(Dancer) + " Drunkards: " + length(Drunkard) + 
			  " Hippies: " + length(Hippie) + " Druggies: " + length(Druggie) + 
			  " Newbies: " + length(Newbie); 
		
		// generate nb_stages stages in the center of the map
		create Stage number: nb_stages {
			self.location <- {rnd(25,75), rnd(25,75)};
		}
	}
	
	reflex update_avg_happiness {
		dancer_avg_hap <- (Dancer sum_of each.happiness) / length(Dancer);
	 	drunkard_avg_hap <- (Drunkard sum_of each.happiness) / length(Drunkard);
		hippie_avg_hap <- (Hippie sum_of each.happiness) / length(Hippie);
		druggie_avg_hap <- (Druggie sum_of each.happiness) / length(Druggie);
		newbie_avg_hap <- (Newbie sum_of each.happiness) / length(Newbie);
	}
	
}

/* ------------------------- Guests ---------------------- */
species Guest skills: [fipa, moving] {
	int alchool;
	int drugs;
	int dance;
	int happiness <- 50;
	
	int guest_size <- 1;
	bool arrived <- false;
	int start_stay;
	int max_stay <- rnd(20,30); // max time a guest would stay at one place
	rgb guest_color;
	Building target;
	string genre <- music_genres[rnd(length(music_genres)-1)];
	Guest talking_to;
	
	// wander when nothing to do
	reflex wander {
		do wander bounds: circle(0.5);
	}
	
	// decide to go somewhere or not
	reflex listen_stage when: target = nil and !empty(cfps) {
		message request <- cfps at 0;
		if (request.contents[0] = 'concert') {
			if (request.contents[1] = 'stop') {
				self.target <- nil;
				self.arrived <- false;
			} else if (request.contents[1] = 'start'){
				if (request.contents[2] = self.genre){
					self.target <- request.sender;
					self.target.crowd <+ self;
					write "Guest " + self.name + " [" +alchool+","+drugs+","+dance+"]" + " is going to stage " + self.target.name;
				} else {
					int random_number <- rnd(100);
					if (random_number < 70){
						// go to a random bar with a chance of 70%
						self.target <- list(Bar)[rnd(length(list(Bar))-1)];
						write "Guest " + self.name + " [" +alchool+","+drugs+","+dance+"]" + " is going to bar " + self.target.name;
					} else {
						// otherwise just wander around
						self.target <- nil;
						self.arrived <- false;
					}
				}
			}
		}
	}
	
	// get out of a place if stayed too much time
	reflex leave_place when: self.target != nil and arrived and int(time) >= self.start_stay + self.max_stay {
		self.target <- nil;
		self.arrived <- false;
	}
	
	// go to building when the Guest is not yet arrived there but has it as a target
	reflex go_to_building when: self.target != nil {
		if(location distance_to(self.target) > (self.target.build_size + 2)) {
			do goto target:{self.target.location.x + 2, self.target.location.y + 2};	
		} else if(!arrived) {
			// start the staying time
			self.start_stay <- int(time);
			self.arrived <- true;
			if (species(self.target) = Stage){
				// if it got on the stage the dancing appetite decreases
				self.dance <- self.dance - 2*rnd(attr_change_min, attr_change_max);
			} else if (species(self.target) = Bar){
				// if it got at the bar the alchool lvl increases
				self.alchool <- self.alchool + 2*rnd(attr_change_min, attr_change_max);
			}
		}
	}
	
	// Once guest's are at one specific building they will chose someone to talk to,
	// there will be a cooling timer to start another conversation so they don't speak,
	// to the previous guest
	reflex choose_person_to_talk when: self.target != nil 
								 and self.arrived 
								 and !empty(target.crowd) 
								 and int(time) mod rnd(2,4) = 0 
								 and talking_to = nil {
		Guest guest <- (target.crowd-self) first_with (each.talking_to = nil);
		if(guest != nil) {
			self.talking_to <- guest;
			guest.talking_to <- self;	
			// write name + " to: " + talking_to.name + "\n";
		}
	}
	
	action increase_happiness {
		self.happiness <- self.happiness + rnd(attr_change_min, attr_change_max);
	}
	
	action decrease_happiness {
		self.happiness <- self.happiness - rnd(attr_change_min, attr_change_max);
	}
	
	action do_drugs {
		self.drugs <- self.drugs + rnd(attr_change_min, attr_change_max);
	}
	
	action drink_alchool {
		self.alchool <- self.alchool + rnd(attr_change_min, attr_change_max);
	}
	
	action dance_together {
		self.dance <- self.dance + rnd(attr_change_min, attr_change_max);
	}
}

// always interested in partying -> #orange
species Dancer parent: Guest {
	aspect default {
		draw sphere(guest_size) color: self.guest_color;
		draw copy_between(self.name, 6, length(self.name)) color: #black font: font('Helvetica', 10, #bold) 
			at: self.location+{0,0,self.guest_size*2.2};
	}
	
	reflex talking when: talking_to != nil and target != nil{
		switch(species(talking_to)) {
			match Dancer {
				do increase_happiness;
				do dance_together;
			} 
			match Drunkard {
				do decrease_happiness;
				do drink_alchool;
			}
			match Druggie {
				do do_drugs;
			}
			match Hippie {
				do increase_happiness;
			}
		}
		talking_to <- nil;
	}
}

// always interested in drinking -> #violet
species Drunkard parent: Guest {
	aspect default {
		draw sphere(guest_size) color: self.guest_color;
		draw copy_between(self.name, 8, length(self.name)) color: #black font: font('Helvetica', 10, #bold) 
			at: self.location+{0,0,self.guest_size*2.2};
	}
	
	reflex talking when: talking_to != nil and target != nil {
		switch(species(talking_to)) {
			match Dancer {
				do increase_happiness;
				do dance_together;
			} 
			match Drunkard {
				do decrease_happiness;
				self.alchool <- self.alchool - rnd(attr_change_min, attr_change_max); 
				write "xxxxxxxxxxxx Fight on " + target.name + " with " + talking_to.name + " xxxxxxxxxxx";
			}
			match Druggie {
				do increase_happiness;
				do do_drugs;
			}
			match Hippie {
				do increase_happiness;
			}
			match Newbie {
				do increase_happiness;
			}
		}
		talking_to <- nil;
	}
}

// always interested in alternative life style -> #green
species Hippie parent: Guest {
	aspect default {
		draw sphere(guest_size) color: self.guest_color;
		draw copy_between(self.name, 6, length(self.name)) color: #black font: font('Helvetica', 10, #bold) 
			at: self.location+{0,0,self.guest_size*2.2};
	}
	
	reflex talking when: talking_to != nil and target != nil{
		switch(species(talking_to)) {
			match Dancer {
				do increase_happiness;
				do dance_together;
			} 
			match Drunkard {
				do decrease_happiness;
				do drink_alchool;
			}
			match Druggie {
				do increase_happiness;
				do do_drugs;
			}
			match Hippie {
				do increase_happiness;
			}
		}
		talking_to <- nil;
	}
}

// always interested in taking drugs and having fun -> #blue
species Druggie parent: Guest {
	aspect default {
		draw sphere(guest_size) color: self.guest_color;
		draw copy_between(self.name, 7, length(self.name)) color: #black font: font('Helvetica', 10, #bold) 
			at: self.location+{0,0,self.guest_size*2.2};
	}
	
	reflex talking when: talking_to != nil and target != nil {
		switch(species(talking_to)) {
			match Dancer {
				do dance_together;
			} 
			match Drunkard {
				do decrease_happiness;
				do drink_alchool;
			}
			match Druggie {
				do increase_happiness;
				do do_drugs;
			}
			match Hippie {
				do increase_happiness;
				do do_drugs;
			}
			match Newbie {
				do do_drugs;
			}
		}
		talking_to <- nil;
	}
}

// interested in trying various things -> #yellow
species Newbie parent: Guest {
	aspect default {
		draw sphere(guest_size) color: self.guest_color;
		draw copy_between(self.name, 6, length(self.name)) color: #black font: font('Helvetica', 10, #bold) 
			at: self.location+{0,0,self.guest_size*2.2};
	}
	
	reflex talking when: talking_to != nil and target != nil{
		switch(species(talking_to)) {
			match Newbie {
				self.happiness <- self.happiness - rnd(attr_change_min, attr_change_max);
			} 
			match Drunkard {
				do increase_happiness;
				do copy_attributes;
			}
			match Druggie {
				do increase_happiness;
				do copy_attributes;
			}
			match Hippie {
				do increase_happiness;
				do copy_attributes;
			}
			match Dancer {
				do increase_happiness;
				do copy_attributes;
			}
		}
		talking_to <- nil;
	}
	
	action copy_attributes {
		self.drugs <- talking_to.drugs;
		self.alchool <- talking_to.alchool;
		self.dance <- talking_to.dance;
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
		draw at(self.name,5) at: self.location+{0,0,self.stage_size*1.2} color: #black font: font('Helvetica', 15, #bold);
	}
	
	//When the show is over, remove stage from the stages list and remove stage util from the guests and reset them 
	reflex shutdown_show when: time >= start_time + show_duration {
		write "\n:x " + self.name + " concert of " + self.genre + " has finished :x";	
		// anounce Guests about show end
		if (!empty(crowd)){
			do start_conversation (to: self.crowd, protocol: 'fipa-propose', performative: 'cfp', contents: ['concert', 'stop']);
		}
		
		// change location when concert finished
		self.location <- {rnd(25,75),rnd(25,75)};
		do set_utilities;
		write "\n" + self.name + " will start a concert of " + self.genre;
	}
	
	// resend calls to concert once in 20 to 50 simulations
	reflex resend_data when: int(time) mod rnd(15,20) = 0 {
		do start_conversation (to: list(agents of_generic_species Guest), protocol: 'fipa-propose', performative: 'cfp', 
			contents: ['concert', 'start', self.genre]);
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
			contents: ['concert', 'start', self.genre]);
	}
	
}

// place where gusts can drink
species Bar parent: Building {
	
	aspect default {
		draw square(build_size*2) color: #cyan at: self.location-{build_size,0};
		draw square(build_size*2) color: #cyan at: self.location+{build_size,0};
		draw cube(build_size) color: #blue at: self.location-{build_size*0.5,0};
		draw cube(build_size) color: #blue at: self.location+{build_size*0.5,0};
		draw at(self.name,3) at: self.location+{0,0,build_size*1.2} color: #black font: font('Helvetica', 15, #bold);
	}
}

experiment start_festival  type: gui {
	output
	{
		display chart_display type: opengl {
			chart "Happinness by guest type" type:series{
				data "Dancer" value:  dancer_avg_hap color: #orange;
				data "Drunkard" value:  drunkard_avg_hap color: #violet;
				data "Hippie" value:  hippie_avg_hap color: #green;
				data "Druggie" value:  druggie_avg_hap color: #blue;
				data "Newbie" value:  newbie_avg_hap color: #yellow;
			}
		}
		
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
