select EFTRR.dbo.MapStateID(ms1.stateID), EFTRR1.dbo.MapStateID(ms.stateID) 
from EFTRR.dbo.MachineState ms
full outer join EFTRR1.dbo.MachineState ms1
on EFTRR1.dbo.MapStateID(ms1.stateID) = EFTRR.dbo.MapStateID(ms.stateID)
where ms.machineStateID is null
or ms1.machineStateID is null