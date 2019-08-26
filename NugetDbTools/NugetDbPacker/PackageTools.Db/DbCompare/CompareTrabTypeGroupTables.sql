select	m0.tranType, m0.[group], m1.tranType machine1, m1.[group] state1
from	(
			select	m.tranType, s.[group]
			from	EFTRR.dbo.TranType m
			join	EFTRR.dbo.tranTypeGroup s
				on	s.tranTypeID = m.tranTypeID
			) m0
full outer join (
			select	m.tranType, s.[group]
			from	EFTRR1.dbo.TranType m
			join	EFTRR1.dbo.tranTypeGroup s
				on	s.tranTypeID = m.tranTypeID
			) m1
	on	m1.tranType = m0.tranType
	and m1.[group] = m0.[group]
where m0.tranType is null
or m1.tranType is null
order by coalesce(m0.tranType, m1.tranType), coalesce(m0.[group], m1.[group])