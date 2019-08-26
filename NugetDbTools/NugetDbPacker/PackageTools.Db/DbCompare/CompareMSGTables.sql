select *
from (
		select	*
		from	EFTRR.dbo.MSG
		) EFTRR
full outer join (
		select	*
		from	 EFTRR1.dbo.MSG
		) EFTRR1
	on	EFTRR1.msg = EFTRR.msg
	and	EFTRR1.msgTypeID = EFTRR.msgTypeID
where EFTRR.msg is null
or EFTRR1.msg is null
order by coalesce(EFTRR.msg, EFTRR1.msg), coalesce(EFTRR.msgTypeID, EFTRR1.msgTypeID)
