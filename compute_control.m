function [u, state_des] = compute_control(C_stacked,t,total_dt,state)
    
    [xe_des, xe_d_des, xs_dd_des, w_d_des, th1_dd_des, th2_dd_des, state_des] = ...
        compute_state_and_derivatives(C_stacked,t,total_dt);
        
    [xs_des, Rg_des, th1_des, th2_des, xs_d_des, w_des, th1_d_des, th2_d_des] = state_from_vector(state_des);

    if(exist('state','var'))
        u = feedback_linearization(xs_des, xe_des, Rg_des, th1_des, th2_des, xs_d_des, xe_d_des, w_des, th1_d_des, th2_d_des, xs_dd_des, w_d_des, th1_dd_des, th2_dd_des, state);
    else
        u = feedback_linearization(xs_des, xe_des, Rg_des, th1_des, th2_des, xs_d_des, xe_d_des, w_des, th1_d_des, th2_d_des, xs_dd_des, w_d_des, th1_dd_des, th2_dd_des);
    end
end