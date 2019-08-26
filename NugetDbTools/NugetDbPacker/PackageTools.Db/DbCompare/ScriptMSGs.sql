declare @msgPrefix varchar(50) = 'EFT%'
declare @procFilter varchar(max) = 'MSG%'

declare	@msgs table (
	msg			varchar(50),
	msgType		varchar(50),
	msgID		int primary key
)
insert	@msgs(msg, msgType, msgID)
select	msg, msgType, msgID
from	dbo.MSG m
join	dbo.MSGType my
	on	my.msgTypeID = m.msgTypeID
where	msg like @msgPrefix

declare	@configurators table(
	[schema]	sysname null,
	[procedure]	sysname null,
	msg			varchar(50),
	msgID		int
	--primary key (msgID, [schema], [procedure])
)

declare @filters table (
	filter		varchar(50)
)

insert	@filters
select	item
from	dbo.CommaSplit(@procFilter)

insert @configurators ([schema], [procedure], msg, msgID)
select	s.name [schema], p.name [procedure], m.msg, m.msgID
from	@msgs m
left join (
			sys.sql_modules sm
	join	sys.procedures p
		on	p.object_id = sm.object_id
	join	@filters f
		on	p.name like f.filter
	join	sys.schemas s
		on	s.schema_id = p.schema_id
	)
	on	charindex('''' + m.msg + '''', sm.definition) > 0
order by msgID, [schema], [procedure]

declare	@configuratorGroups table(
	[schema]	sysname null,
	[procedure]	sysname null,
	msgID		int
	--primary key (msgID, [schema], [procedure])
)

insert @configuratorGroups ([schema], [procedure], msgID)
select	[schema], [procedure], min(msgID)
from	@configurators
where	[schema] is not null
group by [schema], [procedure]

declare	@lines table(
	machineID		int,
	part			int,
	line_no			int,
	line			varchar(max)
	--primary key (machineID, part, line_no)
)

insert	@lines
values	(0, 1, 1, 'CREATE PROCEDURE [EFT].[ConfigureAllMSGs]'),
		(0, 1, 2, 'AS'),
		(0, 1, 3, 'BEGIN'),
		(0, 3, 1, 'END'),
		(0, 3, 1, 'GO')

--insert	@lines
--select	0, 2, m.msgID * 2, '	IF	dbo.MapMSG(''' + msg + ''') IS NULL'
--from	@configuratorGroups g
--join	@msgs m
--	on	m.msgID = g.msgID
--where	[schema] is not null

insert	@lines
select	0, 2, m.msgID * 2 + 1, '	EXEC ' + [schema] + '.' + [procedure]
from	@configuratorGroups g
join	@msgs m
	on	m.msgID = g.msgID
where	[schema] is not null

insert	@lines
select	0, 2, msgID * 2, '	-- MSG <' + msg + '> configurator not found'
from	@configurators
where	[schema] is null

select	line
from	@lines
order by machineID, part, line_no