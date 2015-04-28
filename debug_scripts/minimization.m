clear all;

%Example problem in 3D to see how fmincon works : let us consider the unit cube and a simple plan that is
%parallel to the plan that intersects it at [0;0;0][1;1;1],[1;1;0] and [0;1;1]
%(intuitive "diagonal" plan), but is translated upwards by 0.5, therefore intersecting the
%cube at :[0;0.5;0],[0.5;1;0] and [0;1;0.5].
%The equation of this plan is -x+y-z=0.5
%Let us find the point that minimizes the distance between [1;1;0] (vertice
%of the cube) and this plan (projection), with the condition that this
%point is also contained in the unit cube. 
%A drawing shows intuitively immediatly that this point is [0.5;1;0], and
%this minimization program confirms it.

%@(x)Utilities.euclidianDistance(x,[1;1;0]) is the euclidian distance
%between variable x and [1;1;0].
%[1;1;0] is the starting point.
%[-1,1,-1] is the tuple that, multiplied by [x;y;z] will give the left side
%of the plan's equation.
%[0.5] is the right side.
%[0;0;0] and [1;1;1] are the boundaries that constrain the solution point,
%which here correspond to the unit cube.

disp('Solution to the example problem described in the comments :');
[x,fval,exitflag,output] = fmincon(@(x)Utilities.euclidianDistance(x,[1;1;0]),[1;1;0],[],[],[-1,1,-1],[0.5],[0;0;0],[1;1;1]);
display(x);


%Let us now apply fmincon to our TVM constraint problem.

%This first paragraph will set up the CmaesBox Object and print some of its
%properties for understanding. Loading will be long.
a=CmaesBox; %create the object.
a.load_xls('C:\Users\Felix\code\autoCalibrationProject\xls\Cmaes_210E_program.xlsx'); %load the first column of the program (set of properties for a).
disp('Knobs are in the hyperplan when pems and beats TVM values are equal.');
disp('TVM value calculated with the pems data coming from non-broken sensors :');
disp(a.TVM_reference_values.pems);
disp('TVM value calculated from a first beats run with all the knobs left to one, using only the links with non-broken sensors :');
disp(a.TVM_reference_values.beats);

%As you can see, this two value differ for several billions. I do not know
%if it is normal. My problem is that I cannot make the beats and pems
%values be equal (which is : make the knobs be inside the hyperplan) if the values of the
%knobs stay inside their boundaries (I am tuning all the 11 knobs in the scenario that don't have working sensors) :

disp('TVM value calculated from a first beats run with all the knobs left to one + new contribution of the knobs set such that all the source knobs are zero and all the sink knobs are their max boundaries (nearest point to the hyperplan possible inside the boundaries):');
disp(a.compute_TVM_with_knobs_vector(a.knobs.knob_boundaries_max));
disp('As you can see, this value is still far from the pems one. So we are not in the plan');
%As you can see, the two values are still far away.
%Logically, whatever the initial point, fmincon will find this same solution telling me that the solution is
%out of boundaries : 

disp('fmincon gives of course the same solution, whatever the starting point :');
disp(a.project_on_correct_TVM_subspace([1;1;1;1;1;1;1;1;1;1;1]));
