select *
from RapidDB.Rapid.Currency RapidDB
full outer join RapidDB1.Rapid.Currency RapidDB1
on RapidDB1.code = RapidDB.code
where RapidDB.code is null
or RapidDB1.code is null