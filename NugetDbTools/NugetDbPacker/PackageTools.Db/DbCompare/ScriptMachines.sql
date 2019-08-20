declare @machinePrefix varchar(50) = 'Shipment%'
declare @procFilter varchar(max) = 'Machine_%,Create%'

declare	@machines table (
	machine			varchar(50),
	machineGroup	varchar(50),
	initialState	varchar(50),
	machineID		int primary key
)
insert	@machines(machine, machineGroup, initialState, machineID)
select	machine, machineGroup, s.state initialState, machineID
from	dbo.Machine m
join	dbo.State s
	on	s.stateID = m.initialStateID
join	dbo.MachineGroup mg
	on	mg.machineGroupID = m.machineGroupID
where	machine like @machinePrefix

declare	@configurators table(
	[schema]	sysname,
	[procedure]	sysname,
	machine		varchar(50),
	machineID	int
	--primary key (machineID, [schema], [procedure])
)

declare @filters table (
	filter		varchar(50)
)

insert	@filters
select	item
from	dbo.CommaSplit(@procFilter)

insert @configurators ([schema], [procedure], machine, machineID)
select	s.name [schema], p.name [procedure], m.machine, m.machineID
from	@machines m
left join (
			sys.sql_modules sm
	join	sys.procedures p
		on	p.object_id = sm.object_id
	join	@filters f
		on	p.name like f.filter
	join	sys.schemas s
		on	s.schema_id = p.schema_id
	)
	on	charindex('''' + m.machine + '''', sm.definition) > 0
order by machineID, [schema], [procedure]

declare	@lines table(
	machineID		int,
	part			int,
	line_no			int,
	line			varchar(max)
	--primary key (machineID, part, line_no)
)

insert	@lines
values	(0, 1, 1, 'CREATE PROCEDURE [EFT].[Configure_Machines]'),
		(0, 1, 2, 'AS'),
		(0, 1, 3, 'BEGIN'),
		(0, 3, 1, 'END'),
		(0, 3, 1, 'GO')

insert	@lines
select	0, 2, machineID * 2, '	IF	dbo.MapMachine(''' + machine + ''') IS NULL'
from	@configurators

insert	@lines
select	0, 2, machineID * 2 + 1, '		exec ' + [schema] + '.' + [procedure]
from	@configurators

select	line
from	@lines
order by machineID, part, line_no