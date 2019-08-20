select *
from (
		select	msg.msg, m.machine, s.state
		from	EFTRR.dbo.MSG msg
		join	EFTRR.dbo.MSGrouping msgg
			on	msgg.msgID = msg.msgID
		join	EFTRR.dbo.MachineState ms
			on	ms.machineStateID = msgg.machineStateID
		join	EFTRR.dbo.Machine m
			on	m.machineID = ms.machineID
		join	EFTRR.dbo.State s
			on	s.stateID = ms.stateID
		) EFTRR
full outer join (
		select	msg.msg msg1, m.machine machine1, s.state state1
		from	EFTRR1.dbo.MSG msg
		join	EFTRR1.dbo.MSGrouping msgg
			on	msgg.msgID = msg.msgID
		join	EFTRR1.dbo.MachineState ms
			on	ms.machineStateID = msgg.machineStateID
		join	EFTRR1.dbo.Machine m
			on	m.machineID = ms.machineID
		join	EFTRR1.dbo.State s
			on	s.stateID = ms.stateID
		) EFTRR1
	on	EFTRR1.msg1 = EFTRR.msg
	and	EFTRR1.machine1 = EFTRR.machine
	and	EFTRR1.state1 = EFTRR.state
where EFTRR.msg is null
or EFTRR1.msg1 is null
order by coalesce(EFTRR.msg, EFTRR1.msg1), coalesce(EFTRR.machine, EFTRR1.machine1), coalesce(EFTRR.state, EFTRR1.state1)
