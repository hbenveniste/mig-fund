using Mimi

@defcomp migration begin
    regions       = Index()
    agegroups     = Index()

    move          = Variable(index=[time,regions,regions])
    migstock      = Variable(index=[time,regions,regions])
    rem           = Variable(index=[time,regions,regions])
    remshare      = Variable(index=[time,regions,regions])
    entermig      = Variable(index=[time,regions])
    leavemig      = Variable(index=[time,regions])
    deadmig       = Variable(index=[time,regions])
    deadmigcost   = Variable(index=[time,regions])
    receive       = Variable(index=[time,regions])
    send          = Variable(index=[time,regions])
    remittances   = Variable(index=[time,regions])

    population    = Parameter(index=[time,regions])
    populationin1 = Parameter(index=[time,regions])
    income        = Parameter(index=[time,regions])
    popdens       = Parameter(index=[time,regions])
    vsl           = Parameter(index=[time,regions])
    lifeexp       = Parameter(index=[time,regions])

    distance      = Parameter(index=[regions,regions])
    migdeathrisk  = Parameter(index=[regions,regions])
    remres        = Parameter(index=[regions,regions])            # residuals from estimation of remshare, used in gravity estimation
    remcost       = Parameter(index=[regions,regions])
    comofflang    = Parameter(index=[regions,regions])   
    policy        = Parameter(index=[regions,regions])            # 1 represents implicit current border policy. Can be decreased for stronger border policy, or increased for more open borders.
    migstockinit  = Parameter(index=[regions,regions])
    gravres       = Parameter(index=[regions,regions])            # residuals from gravity to project migration flows

    ageshare      = Parameter(index=[agegroups])
    agegroupinit  = Parameter(index=[regions,regions,agegroups])

    beta0         = Parameter(default = -19.251)       
    beta1         = Parameter(default = 0.689)
    beta2         = Parameter(default = 0.686)
    beta3         = Parameter(default = 0.042)
    beta4         = Parameter(default = 0.417)
    beta5         = Parameter(default = 0.830)
    beta6         = Parameter(default = 0.139)
    beta7         = Parameter(default = -1.297)       
    beta8         = Parameter(default = 0.011)         
    beta9         = Parameter(default = -9.670)        
    beta10        = Parameter(default = 1.743)          
    delta0        = Parameter(default = 3.418)
    delta1        = Parameter(default = -0.241)
    delta2        = Parameter(default = -0.362)
    delta3        = Parameter(default = -5.953)


    function run_timestep(p,v,d,t)
        if is_first(t)
            for r in d.regions
                for r1 in d.regions
                    v.move[t, r, r1] = 0.0
                    v.migstock[t, r, r1] = 0.0
                    v.rem[t, r, r1] = 0.0
                    v.remshare[t, r, r1] = 0.0
                end
                v.entermig[t, r] = 0.0
                v.leavemig[t, r] = 0.0
                v.deadmig[t, r] = 0.0
                v.deadmigcost[t, r] = 0.0
                v.receive[t, r] = 0.0
                v.send[t, r] = 0.0
                v.remittances[t, r] = 0.0
            end
        else
            # Calculating the number of people migrating from one region to another, based on a gravity model including per capita income.
            # Population is expressed in millions, distance in km.

            for destination in d.regions
                ypc_dest = mean([p.income[TimestepIndex(t10), destination] / p.population[TimestepIndex(t10), destination] * 1000.0 for t10 in max(1,t.t-10):t.t])
                for source in d.regions
                    ypc_source = mean([p.income[TimestepIndex(t10), source] / p.population[TimestepIndex(t10), source] * 1000.0 for t10 in max(1,t.t-10):t.t])
                    ypc_ratio = ypc_dest / ypc_source
                    # Need to start when zero-migration scenarios start + steady state after 2300: no more migration
                    if t >= TimestepValue(2015) && source != destination && t <= TimestepValue(2300)
                        move = p.policy[source, destination] * (p.gravres[source,destination] + exp(p.beta0) * p.populationin1[t, source]^p.beta1 * p.populationin1[t, destination]^p.beta2 * ypc_source^p.beta4 * ypc_dest^p.beta5 * p.distance[source, destination]^p.beta7 * exp(p.beta8*p.remres[source, destination]) * exp(p.beta9*p.remcost[source,destination]) * exp(p.beta10*p.comofflang[source,destination]))
                    else
                        move = 0.0
                    end
                    v.move[t, source, destination] = move
                end
            end

            for destination in d.regions
                entermig = 0.0
                for source in d.regions
                    leaveall = sum(v.move[t, source, :])
                    if leaveall > p.populationin1[t, source]
                        entermig += v.move[t, source, destination] / leaveall * p.populationin1[t, source]
                    else
                        entermig += v.move[t, source, destination]
                    end
                end
                v.entermig[t, destination] = entermig
            end

            for source in d.regions
                leavemig = 0.0
                leaveall = sum(v.move[t, source, :])
                for destination in d.regions
                    if leaveall > p.populationin1[t, source]
                        leavemig += v.move[t, source, destination] / leaveall * p.populationin1[t, source]
                    else
                        leavemig += v.move[t, source, destination]
                    end
                end
                v.leavemig[t, source] = leavemig
            end

            # Calculating the risk of dying while attempting to migrate across borders: 
            # We use data on migration flows between regions in period 2005-2010 from Abel [2013], used in the SSP population scenarios
            # And data on missing migrants in period 2014-2018 from IOM (http://missingmigrants.iom.int/)
            for r in d.regions
                v.deadmig[t, r] = 0.0               # consider risk of dying based on origin region
                v.deadmigcost[t, r] = 0.0           # use VSL from migrant: max(mean(VSL_s,VSL_d),VSL_s)
                for destination in d.regions
                    # We count all migrants perishing on the way
                    v.deadmig[t, r] += p.migdeathrisk[r, destination] * v.move[t, r, destination]
                    # We count as climate change damage only those attributed to differences in income resulting from climate change impacts
                    v.deadmigcost[t, r] += max((p.vsl[t, r] + p.vsl[t, destination])/2, p.vsl[t, r]) * p.migdeathrisk[r, destination] * v.move[t, r, destination] / 1000000000.0
                end
                if v.deadmig[t, r] > p.populationin1[t, r]
                    v.deadmig[t, r] = p.populationin1[t, r]
                end
            end

            # Adding a stock variable indicating how many immigrants from a region are in another region.
            # Shares of migrants per age group are based on SSP projections for 2015-2100. Linear interpolation for this period, then shares maintained constant until 3000.
            for source in d.regions
                for destination in d.regions
                    if t < TimestepValue(2015)
                        v.migstock[t, source, destination] = 0.0
                    elseif t == TimestepValue(2015)
                        # Attribute initial migrant stock to ensure some remittances from migrants before 2015 even when borders closed after
                        v.migstock[t, source, destination] = p.migstockinit[source, destination] + v.move[t, source, destination] - v.deadmig[t, source] * (v.leavemig[t, source] != 0.0 ? v.move[t, source, destination] / v.leavemig[t, source] : 0.0)
                    else
                        v.migstock[t, source, destination] = v.migstock[t - 1, source, destination] + v.move[t, source, destination] - v.deadmig[t, source] * (v.leavemig[t, source] != 0.0 ? v.move[t, source, destination] / v.leavemig[t, source] : 0.0)
                    end
                    if t >= TimestepValue(2015)
                        # Remove from stock migrants who migrated after 2015, once they die
                        for ag in d.agegroups
                            if t.t - (2015-1950+1) > p.lifeexp[t, destination] - ag
                                t0 = ceil(Int, t.t - max(0, p.lifeexp[t, destination] - ag))
                                v.migstock[t, source, destination] -= v.move[TimestepIndex(t0), source, destination] * p.ageshare[ag] 
                            end
                        end
                        if t == TimestepValue(2015 )
                            # Remove from stock migrants who migrated prior to 2015 and, in 2015, are older than their destination's life expectancy
                            a0 = ceil(Int, p.lifeexp[t, destination])
                            for a in a0:120
                                v.migstock[t, source, destination] -= p.agegroupinit[source, destination, a+1] 
                            end
                        else
                            # Remove from stock migrants who migrated prior to 2015 and over time get older than their destination's life expectancy
                            a1 = ceil(Int, p.lifeexp[t, destination] - (t.t - (2015-1950+1)))
                            if a1 >= 0 
                                v.migstock[t, source, destination] -= p.agegroupinit[source, destination, a1+1] 
                            end
                        end
                    end
                    if v.migstock[t, source, destination] < 0
                        v.migstock[t, source, destination] = 0
                    end
                end
            end

            # Calculating remshare endogenously:
            for source in d.regions
                for destination in d.regions
                    ypc_d = p.income[t, destination] / p.population[t, destination] * 1000.0
                    ypc_s = p.income[t, source] / p.population[t, source] * 1000.0
                    v.remshare[t,source,destination] = exp(p.delta0) * ypc_s^p.delta1 * ypc_d^p.delta2 * exp(p.delta3*p.remcost[source,destination]) * p.remres[source,destination]
                end
            end

            # Calculating remittances sent by migrants to their origin communities.
            for source in d.regions
                for destination in d.regions
                    # Use not just ypc_dest, but instead max((ypc_dest + ypc_or)/2, ypc_or)
                    ypc_d = p.income[t, destination] / p.population[t, destination] * 1000.0
                    ypc_s = p.income[t, source] / p.population[t, source] * 1000.0
                    ypc = max((ypc_s+ypc_d)/2, ypc_s)

                    # We keep remittances constant over the lifetime of the migrant at remshare:
                    rem = v.migstock[t, source, destination] * v.remshare[t,source, destination] * (1.0 - p.remcost[source, destination]) * ypc / 1000000000
                    v.rem[t, source, destination] = 0.0 #rem
                end
            end

            for source in d.regions
                receive = 0.0
                for destination in d.regions
                    sendall = sum(v.rem[t, :, destination])
                    if sendall > p.income[t, destination]
                        receive += v.rem[t, source, destination] / sendall * p.income[t, destination]
                    else
                        receive += v.rem[t, source, destination]
                    end
                end
                v.receive[t, source] = receive
            end
            
            for destination in d.regions
                send = 0.0
                sendall = sum(v.rem[t, :, destination])
                for source in d.regions
                    if sendall > p.income[t, destination]
                        send += v.rem[t, source, destination] / sendall * p.income[t, destination]
                    else
                        send += v.rem[t, source, destination]
                    end
                end
                v.send[t, destination] = send
            end

            for r in d.regions
                v.remittances[t, r] = v.receive[t, r] - v.send[t, r]
            end
        end
    end
end