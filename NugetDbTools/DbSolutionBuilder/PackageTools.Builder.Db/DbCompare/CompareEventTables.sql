select *
from EFTRR.dbo.Event EFTRR
full outer join EFTRR1.dbo.Event EFTRR1
on EFTRR1.event = EFTRR.event
where EFTRR.event is null
or EFTRR1.event is null