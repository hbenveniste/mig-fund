using Mimi

@defcomp addimpact begin
    regions  = Index()

    elossmig    = Variable(index=[time,regions])
    slossmig    = Variable(index=[time,regions])
    loss     = Variable(index=[time,regions])

    eloss     = Parameter(index=[time,regions])
    sloss     = Parameter(index=[time,regions])
    entercost = Parameter(index=[time,regions])
    leavecost = Parameter(index=[time,regions])
    otherconsloss       = Parameter(index=[time,regions])
    income    = Parameter(index=[time,regions])

    function run_timestep(p,v,d,t)
        if is_first(t)
            for r in d.regions
                v.elossmig[t, r] = 0.0
                v.slossmig[t, r] = 0.0
            end
        else
            for r in d.regions
                v.elossmig[t, r] = min(p.eloss[t, r] - p.entercost[t, r], p.income[t, r])          # remove entercost: remove migration in SLR component
                v.slossmig[t, r] = p.sloss[t, r] - p.leavecost[t, r] + p.otherconsloss[t, r]       # remove leavecost: remove migration in SLR component + add otherconsloss: add lives lost while attempting to migrate
                v.loss[t, r] = (v.elossmig[t, r] + v.slossmig[t, r]) * 1000000000.0
            end
        end
    end
end