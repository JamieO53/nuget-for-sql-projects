-- db1 - CI database
:setvar db1 EFTRR
-- db2 - SQL project database
:setvar db2 EFTRR1
use master
go
create table #objects$(db1) (
    $(db1)Object sysname null,
    $(db1)Type sysname null,
    $(db1)Count bigint
    )
create table #objects$(db2) (
    $(db2)Object sysname null,
    $(db2)Type sysname null,
    $(db2)Count bigint
    )
go
use $(db1)
go
insert  #objects$(db1)
select  s.name + '.' + t.name $(db1)Object,
        t.type_desc $(db1)Type,
        coalesce(sum(p.row_count), 0) $(db1)Count
from    $(db1).sys.objects t
join    $(db1).sys.schemas s
    on  s.schema_id = t.schema_id
left join $(db1).sys.dm_db_partition_stats p
    on  p.object_id = t.object_id
    and t.type_desc = 'USER_TABLE'
where	t.type_desc not in ('SYSTEM_TABLE', 'INTERNAL_TABLE')
	and	t.name not like 'tsu%'
group by s.name, t.name, t.type_desc
go
use $(db2)
go
insert  #objects$(db2)
select  s.name + '.' + t.name $(db2)Object,
        t.type_desc $(db2)Type,
        coalesce(sum(p.row_count), 0) $(db1)Count
from    $(db2).sys.objects t
join    $(db2).sys.schemas s
    on  s.schema_id = t.schema_id
left join $(db2).sys.dm_db_partition_stats p
    on  p.object_id = t.object_id
    and t.type_desc = 'USER_TABLE'
where t.type_desc not in ('SYSTEM_TABLE', 'INTERNAL_TABLE')
group by s.name, t.name, t.type_desc
go
use master
go
 
declare @objects table (
    $(db1)Object sysname null,
    $(db2)Object sysname null,
    $(db1)Count bigint null,
    $(db2)Count bigint null,
    objectName sysname primary key,
    objectType sysname null
    )
insert  @objects
select  $(db1)Object,
        $(db2)Object,
        $(db1)Count,
        $(db2)Count,
        coalesce($(db1)Object, $(db2)Object) objectName,
        coalesce($(db1)Type, $(db2)Type) objectType
from    #objects$(db1) $(db1)
full outer join #objects$(db2) $(db2)
    on  $(db2).$(db2)Object = $(db1).$(db1)Object
    and $(db2).$(db2)Type = $(db1).$(db1)Type
order by objectName
 
select  objectName [Missing object],
        case when $(db1)Object is null then '$(db1)' else '$(db2)' end [database],
        objectType
from    @objects
where   $(db1)Object is null
    or  $(db2)Object is null
 
select  objectName,
        $(db1)Count,
        $(db2)Count
from    @objects
where   $(db1)Count <> $(db2)Count
go
drop table #objects$(db1)
drop table #objects$(db2)
go