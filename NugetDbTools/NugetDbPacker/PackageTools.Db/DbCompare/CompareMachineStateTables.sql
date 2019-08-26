select	m0.machine, m0.state, m1.machine machine1, m1.state state1
from	(
			select	m.machine, s.state
			from	EFTRR.dbo.Machine m
			join	EFTRR.dbo.MachineState ms
				on	ms.machineID = m.machineID
			join	EFTRR.dbo.State s
				on	s.stateID = ms.stateID
			) m0
full outer join (
			select	m.machine, s.state
			from	EFTRR1.dbo.Machine m
			join	EFTRR1.dbo.MachineState ms
				on	ms.machineID = m.machineID
			join	EFTRR1.dbo.State s
				on	s.stateID = ms.stateID
			) m1
	on	m1.machine = m0.machine
	and m1.state = m0.state
where m0.machine is null
or m1.machine is null
order by coalesce(m0.machine, m1.machine), coalesce(m0.state, m1.state)