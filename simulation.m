%% Set Initial Conditions

Rq0 = eye(3); % hover 
Rg0 = axisangle(e2,pi/2); % arm downwards

x0 = vector_from_state(...
    [0;0;Ls_],Rq0,Rg0,...
    [0;0;0],[0;0;0],Rg0.'*[0;0;0]...
);

%% Configure Simulation Parameters
segment_dt = .0001;
total_dt = 1;
n = floor(total_dt/segment_dt);
state = zeros(n,size(x0,1));
state(1,:) = x0;
current_state = x0;

us = zeros(n,6);
[xs, Rq, Rg, xs_d, Om, w] = state_from_vector(x0);


%% Ball trajectory

z0 = [-.5; 0; -4; .5; -.7; 8];

ball_position = zeros(3,n);
ball_velocity = zeros(3,n);

time = 0:segment_dt:total_dt;

for i=1:size(time,2)
   t = time(i);
   ball_position(:,i) = z0(1:3) + z0(4:6)*t - 1/2*g_*t^2*e3;
end


%% Plan Trajectory

trajectory.x = find_coefficients([0;0;0;0],[.3;-.4;0;0],total_dt);
trajectory.y = find_coefficients([0;0;0;0],[0;.1;0;0],total_dt);
trajectory.z = find_coefficients([0;0;0;0],[-.2;.5;0;0],total_dt);
trajectory.a = find_coefficients([0;0;0;0],[pi/3;0;0;0],total_dt); 
trajectory.b = find_coefficients([pi/2;0;0;0],[.9*pi/2;0;0;0],total_dt);
trajectory.g = find_coefficients([0;0;0;0],[pi/10;0;0;0],total_dt);

stacked = [
    trajectory.x; trajectory.y; trajectory.z;
    trajectory.a; trajectory.b; trajectory.g;
];    

%% Dynamic Simulation

xe_rec = zeros(6,n); % records the planned trajectory of end effector
xs_rec = zeros(6,n); % records the trajectory computed with diff. flatness

w_rec = zeros(3,n);  % records the planned gripper ang. vel
Om_rec = zeros(3,n); % records the ang. vel. computed with diff. flatness

percent_done = -1;

for j=1:n
    
    % progress indicator
    percent = floor((j / n)*100);
    if(percent > percent_done)
      fprintf('simulating dynamics: %d%% done.\n',percent);
      percent_done = percent;
    end

    t = segment_dt * j;
    
    % compute feedforward control
    [u_ff, xe_des, xs_des, w_des, Om_des] = compute_control(stacked, t, total_dt);

    record_nominal_trajectory;
    
    % integrate dynamics 
    tspan=segment_dt*(j-1)+[0 segment_dt];
    [~,qs] = ode45(@(t,x) ode(x,u_ff),tspan,current_state);   
    current_state = qs(end,:)';
    
    % reorthonormalize rotation matrices (project back onto manifold)
    [xs, Rq, Rg, xs_d, Om, w] = state_from_vector(current_state);
    [U, ~, V] = svd(Rq);
    Rq = U * V';
    [U, ~, V] = svd(Rg);
    Rg = U * V';

    % record state and control inputs for plotting
    state(j,:) = vector_from_state(xs, Rq, Rg, xs_d, Om, w);
    us(j,:) = u_ff.';
 
end

%% Visualization

plot_sim_results