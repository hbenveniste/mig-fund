using Mimi

@defcomp addpop begin
    regions  = Index()

    enter    = Variable(index=[time,regions])
    leave    = Variable(index=[time,regions])
    deadall     = Variable(index=[time,regions])

    dead     = Parameter(index=[time,regions])
    entermig = Parameter(index=[time,regions])
    leavemig = Parameter(index=[time,regions])
    deadmig  = Parameter(index=[time,regions])

    function run_timestep(p,v,d,t)
        if !is_first(t)
            for r in d.regions
                v.leave[t, r] = p.leavemig[t, r]
                v.enter[t, r] = p.entermig[t, r]
                v.deadall[t, r] = p.dead[t, r] + p.deadmig[t, r]
            end
        end
    end
end