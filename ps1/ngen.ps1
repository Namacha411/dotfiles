Set-Alias ngen @(  
dir (join-path ${env:\windir} "Microsoft.NET\Framework") ngen.exe -recurse |  
sort -descending lastwritetime  
)[0].fullName  
[appdomain]::currentdomain.getassemblies() | %{ngen $_.location}  
