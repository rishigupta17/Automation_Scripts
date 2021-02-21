
# The first execution will create this directory structure
# And the proceeding calls will use it.

New-Item -Force H:\auto_sql\DEV -Type Directory | Out-Null
New-Item -Force H:\auto_sql\TEST -Type Directory | Out-Null

New-Item -Force H:\auto_sql\spool_logs\DEV -Type Directory | Out-Null
New-Item -Force H:\auto_sql\spool_logs\TEST -Type Directory | Out-Null

function Esecute-SQL {
    param($envr)

    # Creation of a main script which includes all other scripts in the directory

    # Set encoding according to sqlplus
    $PSDefaultParameterValues['Out-File:Encoding'] = 'ascii';
    
    # Create a sql file for executing all sqls in the folder
    cd H:\auto_sql\$envr;
    Get-ChildItem -Filter *.sql | foreach-object -process { "@ ./$envr/" + $_ } | out-file ../main.sql;
    cd..;

    # Add a last commit statement
    echo "commit;" >> main.sql;

    # Script Execution

    if($envr.Equals("DEV")) {
        echo exit | sqlplus uname/password@database "@main.sql" > latest_spool_DEV;
    } elseif($envr.Equals("TEST")) {
        echo exit | sqlplus uname/password@database "@main.sql" > latest_spool_TEST;
    }

    del main.sql;

    # Logging

    $date = Get-Date -format "yyyy_MM_dd_HH_mm_ss";
    $user = $env:UserName;

    #Logging in a dedicated log directory
    Copy-Item -Force latest_spool_$envr.txt ./spool_logs/$envr/"spool_$date.txt";

    #Logging in a shared log directory by user
    New-Item -Force Shared_Drive:/auto_sql_logs/$envr/"spool_$user" -Type Directory | Out-Null;
    Copy-Item -Force latest_spool_$envr.txt Shared_Drive:/auto_sql_logs/$envr/"spool_$user"/"spool_$date.txt";

}

