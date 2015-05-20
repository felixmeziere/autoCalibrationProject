% clear
% close all
% load usualsettings
% a.beats_simulation.import_beats_classes;
% a.beats_simulation.create_beats_object(a.beats_parameters);
a.beats_simulation.beats.reset();
a.beats_simulation.run_beats_persistent;
a.beats_simulation.plot_freeway_contour;
a.beats_simulation.beats.reset();
a.beats_simulation.beats.set.knob_for_offramp_link_id(-781754904,5);
a.beats_simulation.run_beats_persistent;
a.beats_simulation.plot_freeway_contour;
a.beats_simulation.beats.reset();
a.beats_simulation.beats.set.demand_knob_for_link_id(-734823943,10);
a.beats_simulation.run_beats_persistent;
a.beats_simulation.plot_freeway_contour;