select *
from EFTRR.dbo.Machine EFTRR
full outer join EFTRR1.dbo.Machine EFTRR1
on EFTRR1.machine = EFTRR.machine
where EFTRR.machine is null
or EFTRR.machine is null