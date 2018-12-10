function [C_stacked, minval, retcode] = trajectory_optimization(z0,C0)
    
    % TODO : nondimensionalize! 

    global g_
    global e3
    global cost_function
    
    t_apex = z0(6)/g_;

    addpath('/usr/local/lib/matlab/')
   
    zf = (z0(1:3) + z0(4:6) - 1/2*g_*e3);
    zdf = (z0(4:6) - 1*g_*e3);
    
    opt.algorithm = NLOPT_LN_COBYLA;
%     opt.lower_bounds = -30*ones(1,48);
%     opt.upper_bounds = 30*ones(1,48);
    opt.xtol_rel = 1e-3;
    opt.verbose = 1;
    % COST FUNCTION from design_optimizer
    opt.min_objective = @(C) cost_function(C,t_apex,z0);
    
    % EQUALITY CONSTRAINTS on boundary conditions
    opt.h = {
        ... Initial conditions, all zero except for arm swing angle
        @(C) C(1),   @(C)    C(9), @(C) C(17),   @(C)   C(25), @(C) C(33)-pi/2,   @(C) C(41),...        % Init position
        @(C) C(2),   @(C)   C(10), @(C) C(18),   @(C)   C(26),      @(C) C(34),   @(C) C(42),...        % Init velocity
        @(C) 2*C(3), @(C) 2*C(11), @(C) 2*C(19), @(C) 2*C(27),    @(C) 2*C(35), @(C) 2*C(43),...        % Init acceleration
        @(C) 6*C(4), @(C) 6*C(12), @(C) 6*C(20), @(C) 6*C(28),    @(C) 6*C(36), @(C) 6*C(44),...        % Init jerk
        ... Final conditions on end effector position only, match apex of projectile
        @(C) sum(C(1:8)) - zf(1), @(C) sum(C(9:16)) - zf(2), @(C) sum(C(17:24)) - zf(3),...             % Final position
        @(C) C(1:8)*(0:7).' - zdf(1), @(C) C(9:16)*(0:7).' - zdf(2), @(C) C(17:24)*(0:7).' - zdf(3),... % Final velocity
        ... % lock gamma at zero temporarily
        @(C) C(42), @(C) C(43), @(C) C(44), @(C) C(45), @(C) C(46), @(C) C(47), @(C) C(48)...
    };

    % INEQUALITY CONSTRAINTS on maximum effort, maximum attitude, joint range of motion

% put constraints on euler angles
    
    keyframes = 0:.01:1;

%     a: + pi, - pi
%     b: 0, pi
    opt.fc = [
        sample(@(C,t) eval_traj(C(25:32),t) - pi*.8,keyframes);
        sample(@(C,t) -eval_traj(C(25:32),t) - pi*.8,keyframes);
        sample(@(C,t) eval_traj(C(33:40),t) - pi*.9,keyframes);
        sample(@(C,t) -eval_traj(C(33:40),t) - pi*.1,keyframes);
        sample(@(C,t) compute_attitude_angle(C,t,1)-30*pi/180,keyframes);
    ];

    opt.fc_tol = (1e-3)*ones(size(opt.fc));

    [C_stacked, minval, retcode] = nlopt_optimize(opt, C0);

    
    % TODO : this does not use nondimensionalized trajectories!!!
    
end