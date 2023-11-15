#!/bin/bash

###########################################################################
# Script Name: nz_util.sh
# 
# Description: This shell script includes functions for performing
#              common transactions.  Functions included are as follows:
# GatherStats
# TruncateTable
# LoadFromFixedFile
# LoadFromDelimited
# LoadFromSQL
# ExecuteCommand
# WriteCSV
#
# Authors:
# DATE      Author            DESCRIPTION
# --------  ----            ------------------------------------------------------
# 05/29/23  Tom McGeehan    Initial Revision.
#

##########################################################################
# Modification History:
# DATE      INIT    DESCRIPTION
# --------  ----    ------------------------------------------------------
# 05/29/23  TFMV    Initial Revision.
#
# GatherStats ${_nz_table} ${_nz_db}
# Input: ${_nz_table}   -- name of NPS table to gather stats on
#        ${_nz_db)      -- name of NPS database where _nz_table resides
# Output: NPS statistics gathered for specified table
# Return: 0  Successful
#         20 NPS Error
#         30 Invalid Arguments
##########################################################################
function GatherStats {
   if [[ $# -eq 2 ]] ; then
      _nz_table=$1
      _nz_db=$2
      _cc="GENERATE STATISTICS ON ${_nz_db}..${_nz_table};"

      echo "Generating statistics on ${_nz_table} at $(date)"
      ExecuteCommand "${_cc}" "${_nz_db}"
      _rc=$?

      if [[ ${_rc} -eq 0 ]] ; then
         echo "Statistics gathered on ${_nz_table}"
      else
         _rc=20
         echo "NPS ERROR DURING GENERATE STATISTICS ON ${_nz_table}"
      fi
   else
      echo "Invalid Number of Command Line Arguments Required: 2; Actual: $# [GatherStats()]"
      _rc=30
   fi
   return ${_rc}
} # End GatherStats


##########################################################################
# Modification History:
# DATE      INIT    DESCRIPTION
# --------  ----    ------------------------------------------------------
# 05/29/23  TFMV    Initial Revision.
#
# TruncateTable ${_nz_table} ${_nz_db}
# Input: ${_nz_table}   -- name of NPS table to truncate
#        ${_nz_db)      -- name of NPS database where _nz_table resides
# Output: NPS Table Truncated
# Return: 0  Successful
#         20 NPS Error
#         30 Invalid Arguments
##########################################################################
function TruncateTable {
   if [[ $# -eq 2 ]] ; then
      _nz_table=$1
      _nz_db=$2
      _command="TRUNCATE TABLE ${_nz_table};"
      
      nzsql -db ${_nz_db} -c "$_command" -time
      _rc=$?

      if [[ $_rc -eq 0 ]]; then
         echo "TABLE $_nz_table TRUNCATED"
      else
         echo "NPS ERROR DURING TRUNCATE $_nz_table"
         _rc=20
      fi
   else
      echo "Invalid Number of Command Line Arguments [TruncateTable()]"
      _rc=30
   fi
   return $_rc
} # End TruncateTable

##########################################################################
# Modification History:
# DATE      INIT    DESCRIPTION
# --------  ----    ------------------------------------------------------
# 05/29/23  TFMV    Initial Revision.
#
# LoadFromFixedFile ${_nz_table} ${_nz_db} ${_load_file} ${_ctl_file} ${
# Input: ${_nz_table}   -- name of NPS table to load
#        ${_nz_db)      -- name of NPS database where _nz_table resides
#        ${_load_file}  -- full path to fixed length file to load
#        ${_ctl_file}   -- full path to NPS control file
#        ${_recLength}  -- length of each record in the fixed length file
# Output: Data loaded into NPS structure
# Return: 0  Successful
#         10 Required Files (control and input) Invalid
#         20 NPS Error
#         30 Invalid Arguments
##########################################################################
function LoadFromFixedFile {
   if [[ $# -eq 5 ]] ; then
      _nz_table=$1
      _nz_db=$2
      _load_file=$3
      _ctl_file=$4
      _recLength=$(head -1 $_load_file | wc -c -1)

      if [[ -n $_load_file && -n $_ctl_file ]] ; then
         _nzlog="${_LOG}/${_load_file}.log"
         _nzbad="${_LOG}/${_load_file}.bad"
         rm $_nzlog 2>/dev/null
         rm $_nzbad 2>/dev/null
         
         _nzload_opt=" -format FIXED "
         /nz/kit/bin/nzload $_nzload_opt -host $NZ_HOST -db $_nz_db -t $_nz_table -df $_load_file -recLength $_recLength -cf $_ctl_file -bf $_nzbad -lf $_nzlog -ctrlChars
         
         _rc=$?
         
         if [[ $_rc -eq 0 ]]; then
            echo "** BEGIN NZLOAD LOG DISPLAY ** $_nzlog -- "
            cat $_nzlog
            echo "** END NZLOAD LOG DISPLAY ** $_nzlog -- "
            rm $_nzbad 2>/dev/null 
         else
            echo "NPS Errors While Loading $_nz_table from Fixed File"
            cat $_nzlog
            _rc=20
         fi
      else
         echo "** File(s) $_load_file or $_ctl_file Empty or Do not Exist.  **"
         _rc=10
      fi
   else
      echo "Invalid Number of Command Line Arguments [LoadFromFixedFile()]"
      _rc=30
   fi
   return $_rc
} # End LoadFromFixedFile

##########################################################################
# Modification History:
# DATE      INIT    DESCRIPTION
# --------  ----    ------------------------------------------------------
# 05/29/23  TFMV    Initial Revision.
#
# LoadFromDelimited ${_nz_table} ${_nz_db} ${_load_file} ${_delimiter}
# Input: ${_nz_table}   -- name of NPS table to load
#        ${_nz_db)      -- name of NPS database where _nz_table resides
#        ${_load_file}  -- full path to fixed length file to load
#        ${_delimiter}  -- field separator (delimiter) used in _load_file
# Output: Data loaded into NPS structure
# Return: 0  Successful
#         10 Required Files (control and input) Invalid
#         20 NPS Error
#         30 Invalid Arguments
##########################################################################
function LoadFromDelimited {
   if [[ $# -eq 4 ]] ; then
      _nz_table=$1
      _nz_db=$2
      _load_file=$3
      _delimiter=$4

      if [[ -n $_load_file ]] ; then
         _nzlog="${LOG}/${_load_file}.log"
         _nzbad="${LOG}/${_load_file}.bad"
         _nzload_opt=" -delim $_delimiter -ignoreZero YES "

         /nz/kit/bin/nzload $_nzload_opt -host $NZ_HOST -db $_nz_db -t $_nz_table -df $_load_file -bf $_nzbad -lf $_nzlog -ctrlChars

         _rc=$?
         
         if [[ $_rc -eq 0 ]]; then
            echo "** BEGIN NZLOAD LOG DISPLAY ** $_nzlog -- "
            cat $_nzlog
            echo "** END NZLOAD LOG DISPLAY ** $_nzlog -- "
            rm $_nzbad 2>/dev/null 
         else
            echo "NPS Errors While Loading $_nz_table from Delimited File"
            cat $_nzlog
            _rc=20
         fi
      else
         echo "** File $_load_file Empty or Does not Exist.  **"
         _rc=10
      fi 
   else
      echo "Invalid Number of Command Line Arguments [LoadFromDelimited()]"
      _rc=30
   fi
   return $_rc 	
} # End LoadFromDelimited

##########################################################################
# Modification History:
# DATE      INIT    DESCRIPTION
# --------  ----    ------------------------------------------------------
# 05/29/23  TFMV    Initial Revision.
#
# LoadFromSQL        ${_nz_table} ${_nz_db} ${_sql_insert}
# Input: ${_nz_table}   -- name of NPS table to load
#        ${_nz_db)      -- name of NPS database where _nz_table resides
#        ${_enzeeSQL}  -- full path to the NZ sql insert script
# Output: Data loaded into NPS structure
# Return: 0  Successful
#         10 Data file is not found
#         20 NPS Error
#         30 Invalid Arguments
##########################################################################
function LoadFromSQL {
   if [[ $# -eq 3 ]] ; then
      _nz_table=$1
      _sql_insert=$3
      _pid=$$
      _nzlog=${LOG}/${_nz_table}.${_pid}.log

      rm -f $_nzlog 2>/dev/null

      if [[ -n $_sql_insert ]] ; then
         /nz/kit/bin/nzsql -db ${_nz_db} -outputDir $LOG -o $_nzlog -f $_sql_insert -time -v ON_ERROR_STOP=1 -v STARTDT=""
         _rc=$?

         if [[ $_rc -eq 0 ]]; then
            echo "** BEGIN NZLOAD LOG DISPLAY ** $_nzlog -- "
            cat $_nzlog
            echo "** END NZLOAD LOG DISPLAY ** $_nzlog -- "
         else
            echo "NPS Errors While Loading $_nz_table from SQL Script"
            cat $_nzlog
            _rc=20
         fi
      else
         echo "File $_sql_insert does not exist or is empty"
         _rc=10
      fi
   else
      echo "Invalid Number of Command Line Arguments [LoadFromSQL()]"
      _rc=30
   fi

   return $_rc
} # End LoadFromSQL

##########################################################################
# Modification History:
# DATE      INIT    DESCRIPTION
# --------  ----    ------------------------------------------------------
# 05/29/23  TFMV    Initial Revision.
#
# ExecuteCommand ${_nz_command} ${_nz_db}
# Input: ${_nz_command}   -- NPS Command to Execute
#        ${_nz_db}        -- Netezza Database where command should be executed
# Output: Return Code
# Return: 0  Successful
#         20 NPS Error
#         30 Invalid Arguments
##########################################################################
function ExecuteCommand {
   if [[ $# -eq 2 ]] ; then
      _nz_command=$1
      _nz_db=$2
      _s=$$

      nzsql -db $_nz_db -c "$_nz_command" -time -v ON_ERROR_STOP=1
      _rc=$?

      if [[ $_rc -ne 0 ]]; then
         echo "NPS Errors While Attempting to execute command: $_nz_command"
         cat $_nzlog
         _rc=20
         exit $_rc  
      fi

      rm $_nzlog 2>/dev/null
   else
      echo "Invalid Number of Command Line Arguments. Required: 2; Actual: $# [ExecuteCommand()]"
      _rc=30
   fi

   return $_rc
} # End ExecuteCommand

##########################################################################
# Modification History:
# DATE      INIT    DESCRIPTION
# --------  ----    ------------------------------------------------------
# 05/29/23  TFMV    Initial Revision.
#
# WriteCSV ${_delimited_file_name} ${_nz_query} ${_delimiter}
# Input: ${_delimited_file_name}   -- Full path of the desired output (CSV) file
#        ${_nz_db}                 -- Netezza Database where command should be executed
#        ${_nz_query)              -- Query to be executed
#        ${_delimiter}             -- Delimiter to be used in the output file
# Output: File specified by _delimited_file_name containing results
#         from query specified by _nz_query
# Return: 0  Successful
#         20 NPS Error
#         30 Invalid Arguments
##########################################################################
function WriteCSV {
   if [[ $# -eq 4 ]] ; then
      _delimited_file_name=$1
      _nz_db=$2
      _nz_query=$3
      _delimiter=$4
      _nzlog="${LOG}/${_delimited_file_name}.log"

      rm $_nzlog 2>/dev/null

      nzsql -d $_nz_db -c "$_nz_query" -o $_delimited_file_name -F "$_delimiter" -A -q -t -v ON_ERROR_STOP=1
      _rc=$?

      if [[ $_rc -eq 0 ]]; then
         _lines=$(wc -l < $_delimited_file_name)
         echo "File $_delimited_file_name created with $_lines total records"
      else
         echo "NPS Errors While Attempting to Create File $_delimited_file_name"
         cat $_nzlog
         _rc=20
      fi
   else
      echo "Invalid Number of Command Line Arguments [WriteCSV()]"
      _rc=30
   fi

   return $_rc
} # End WriteCSV

##########################################################################
# Modification History:
# DATE      INIT    DESCRIPTION
# --------  ----    ------------------------------------------------------
# 05/29/23  TFMV    Initial Revision.
#
# ReclaimRequest - Insert reclaims request for the table
#
# Input:  ${_db_name} - Data base name
#         ${_tab_name} - Table name
# Output: None
# Return: 0 if successful
#         99 if Failure encountered
#
##########################################################################
#function ReclaimRequest Deprecated


##########################################################################
# Modification History:
# DATE      INIT    DESCRIPTION
# --------  ----    ------------------------------------------------------
# 05/29/23  TFMV    Initial Revision.
#
# GroomTable - Executes Groom Table Command for specified table in specified DB
#
# Input:  ${_db} - Data base name
#         ${_table} - Table name to groom
# Output: None
# Return: 0 if successful
#         99 if Failure encountered
#
##########################################################################
function GroomTable {
   if [[ $# -eq 2 ]] ; then
      _db=$1
      _table=$2

      echo "GROOMING TABLE $_table"

      _cmd="GROOM TABLE $_table"
      ExecuteCommand "$_cmd" $_db
      _rc=$?

      if [[ $_rc -ne 0 ]] ; then
         echo "## ERROR: Inserting Reclaim Record ##"
        _rc=99
      fi
   else
      echo "Invalid Number of Command Line Arguments [ReclaimRequest()]"
      _rc=30
   fi

   return $_rc
} # End GroomTable

##########################################################################
# Modification History:
# DATE      INIT    DESCRIPTION
# --------  ----    ------------------------------------------------------
# 05/29/23  TFMV    Initial Revision.
#
# CreateLoadTable - This function creates a table in the Netezza LOAD_DB
#                   database using the naming convention TABLE_PROCESSID
#                   that contains a single VARCHAR field of size 10000
#
# Input:  ${_PID} - Machine Process ID
#         ${_tab_name} - Target Table
# Output: Table Created in LOAD_DB on Netezza
# Return: 0 if successful
#         30 if invalid number of arguments
#         99 if Failure encountered
#
##########################################################################
function CreateLoadTable {
   if [[ $# -eq 2 ]] ; then
      _PID=$1
      _tab_name=$2

      echo "Creating Table ${LOAD_DB}.${_tab_name}_$_PID"

      _cmd="CREATE TABLE ${_tab_name}_$_PID (FIELD VARCHAR(64000))"
      ExecuteCommand "$_cmd" $LOAD_DB
      _rc=$?

      if [[ $_rc -ne 0 ]] ; then
         echo "## ERROR DURING CREATE LOAD TABLE: ${LOAD_DB}.${_tab_name}_$_PID ##"
         _rc=99
      fi
   else
      echo "Invalid Number of Command Line Arguments [CreateLoadTable()]"
      _rc=30
   fi

   return $_rc
}
 # End CreateLoadTable

##########################################################################
# Modification History:
# DATE      INIT    DESCRIPTION
# --------  ----    ------------------------------------------------------
# 05/29/23  TFMV    Initial Revision.
#
# CreateLoadTableDelimited
#     This function creates a table in the Netezza LOAD_DB
#     database using the naming convention TABLE_PROCESSID
#     that N VARCHAR fields of size 1000
#
# Input:  ${_PID} - Machine Process ID
#         ${_tab_name} - Target Table
#         ${_N} - Number of Fields
# Output: Table Created in LOAD_DB on Netezza
# Return: 0 if successful
#         30 if invalid number of arguments
#         99 if Failure encountered
#
##########################################################################
function CreateLoadTableDelimited {
   if [[ $# -eq 3 ]] ; then
      _PID=$1
      _tab_name=$2
      _N=$3
      _fieldList=""

      for i in $(seq 1 $_N); do 
         _fieldList+="FIELD$i VARCHAR(100),"
      done

      _fieldList=${_fieldList%,}
      
      echo "Creating Table ${LOAD_DB}.${_tab_name}_$_PID"

      _cmd="CREATE TABLE ${_tab_name}_$_PID ($_fieldList)"
      ExecuteCommand "$_cmd" $LOAD_DB
      _rc=$?

      if [[ $_rc -ne 0 ]] ; then
         echo "## ERROR DURING CREATE LOAD TABLE: ${LOAD_DB}.${_tab_name}_$_PID ##"
         _rc=99
      fi
   else
      echo "Invalid Number of Command Line Arguments [CreateLoadTableDelimited()]"
      _rc=30
   fi

   return $_rc
} # End CreateLoadTableDelimited

##########################################################################
# Modification History:
# DATE      INIT    DESCRIPTION
# --------  ----    ------------------------------------------------------
# 05/29/23  TFMV    Initial Revision.
#
# TouchNZTable
#     This function determines if the specified table exists in the
#     specified database in Netezza using the data dictionary (_V_TABLE)
#
# Input:  ${_db}    Name of DB to where the table check should be performed
#         ${_table} Name of the Table within the specified database
# Output: NONE
# Return: 1 IF TABLE EXISTS IN THE SPECIFIED DATABASE
#         0 IF TABLE DOES NOT EXIST IN THE SPECIFIED DATABASE
#
##########################################################################
function TouchNZTable {
    _db=$1
    _table=$2

    _N=`nzsql -db $_db -A -c "SELECT CASE WHEN COUNT(*) = 0 THEN 0 ELSE 1 END AS C \
                              FROM _V_TABLE TAB \
                              WHERE TABLENAME=:TABNAME" \
                              -v TABNAME="'$_table'"`

    return ${_N}
} # End TouchNZTable

##########################################################################
# Modification History:
# DATE      INIT    DESCRIPTION
# --------  ----    ------------------------------------------------------
# 05/29/23  TFMV    Initial Revision.
#
# NzEzLoader  - This function:
#               Creates a Table in LOAD_DB
#               Loads the file into the table
#               Truncates the target table
#               Executes Insert from Load Table to Target Table
#               Generates Stats for Target Table
#               Drops load table
#
# Input:  ${table}       - Target Table
#         ${file)        - File to Load into Target Table
#         ${_db}         - Target Database Where Target Table Resides
#         ${trunc_flag}  - Optional: Pass "NO_TRUNC" if the target
#                            table should not be truncated prior to the
#                            load. The default is to truncate the table.
#         ${n_columns}     - Optional: Use for delimited files.
#                          If the value passed is not (null, 0, 1)
#                          then a table with n_columns is created
#         ${_delim}      - Optional: Use only if n_columns is specified.  Indicates
#                          the field delimiter
#         ${n_skip}      - Optional: Default = 0; Use to specify the number of
#                          records to skip
# Output: NZLOAD options
#
##########################################################################
function NzEzLoader {
    TouchNZTable ${LOAD_DB} ${_table}_${_pid}
    _rc=$?
    
    if [[ ${_rc} -eq 1 ]]; then
        echo ""
        echo "*****************************************************************************"
        echo "******************************INFORMATION************************************"
        echo "*** LOAD TABLE ${LOAD_DB}..${_table}_${_pid} ALREADY EXISTS ***"
        echo "THIS IS A RARE BUT VALID SITUATION"
        echo "${LOAD_DB}..${_table}_${_pid} WILL NOW BE DROPPED"
        nzsql -db ${LOAD_DB} -c "DROP TABLE ${_table}_${_pid}"
        echo ""
        echo "***********************NzEzLoader Resuming Normal Processing ***********************"
        echo ""
    fi
    
    if [ ${n_columns} -gt 1 ]; then
        CreateLoadTableDelimited ${_pid} ${_table} ${n_columns} > $_log
    else
        CreateLoadTable ${_pid} ${_table} > $_log
    fi
    
    _rc=$?
    
    if [[ ${_rc} -ne 0 ]]; then
        echo "###########################################"
        echo "# NETEZZA ERROR WHILE CREATING LOAD TABLE #"
        echo "###########################################"
        cat ${_log}
        exit 1
    fi

    if [ ${n_columns} -gt 1 ]; then
        cat ${_file} | nzload -db ${LOAD_DB} \
        -t ${_table}_${_pid} \
        -lf ${LOG}/${_table}.${ME_DATE}.log \
        -bf ${BAD}/${_tab_name}.bad \
        -delim ${_delim} \
        -skipRows ${n_skip} \
        -quotedValue DOUBLE \
        -fillRecord
    else
        _reclen="`head -1 ${_file} | awk '{print length;exit}'`" 
        cat ${_file} | nzload -db ${LOAD_DB} \
        -t ${_table}_${_pid} \
        -lf ${LOG}/${_table}.${ME_DATE}.log \
        -bf ${BAD}/${_tab_name}.bad \
        -ctrlChars \
        -format FIXED \
        -skipRows ${n_skip} \
        -Layout "VARCHAR BYTES ${_reclen}"
    fi
    
    _rc=$?
    
    if [[ ${_rc} -ne 0 ]]; then
        echo "####################################################################"
        echo "# ERROR DURING LOAD OF FILES INTO ${LOAD_DB}..${_table}_${_pid} #"
        echo "####################################################################"
        cat ${_log}
        exit 1
    fi
    
    echo "${_file} LOADED INTO ${LOAD_DB}..${_table}_${_pid}"
    echo ""
    
    if [[ $_tflag = "TRUNC" ]]; then 
        TruncateTable ${_table} ${_db} > ${_log}
        _rc=$?
        
        if [[ ${_rc} -ne 0 ]]; then
            echo "#############################################"
            echo "# ERROR DURING TRUNCATE OF ${CTDM_TBLS}..${_table} #"
            echo "#############################################"
            cat ${_log}
            exit 1
        fi
        
        echo "${_db}..${_table} TRUNCATED"
        echo ""
    fi

    nzsql -db ${_db} -f ${LOAD_SQL}/${_table}.sql -time -v ON_ERROR_STOP=1 -v TABLENAME="${_table}_${_pid}" -v LOAD_DB=${LOAD_DB} -v CTDM_TBLS=${CTDM_TBLS} -v ME_DATE="${ME_DATE}"> ${_log}
    _rc=$?
    
    if [[ ${_rc} -ne 0 ]]; then
        echo "#######################################################"
        echo "# ERROR DURING LOAD OF ${_db}..${_table} DURING NZSQL #"
        echo "#######################################################"
        cat ${_log}
        exit 1
    fi
    
    echo "${_db}..${_table} LOADED"
    echo ""

    GatherStats "${_table}" "${_db}"  > ${_log}
    _rc=$?
    
    if [[ ${_rc} -ne 0 ]]; then
        echo "#######################################################"
        echo "#      ERROR WHILE GENERATING STATS ON ${_table}      #"
        echo "#######################################################"
        cat ${_log}
        exit 1
    fi
    
    echo "${_db}..${_table} STATS GENERATED"
    echo ""

    ExecuteCommand "DROP TABLE ${_table}_${_pid}" ${LOAD_DB}  > ${_log}
    _rc=$?
    
    if [[ ${_rc} -ne 0 ]]; then
        echo "##########################################"
        echo "# ERROR WHILE DROPPING ${_table}_${_pid} #"
        echo "##########################################"
        cat ${_log}
        exit 1
    fi
    
    rm -f ${_log}
    echo "NzEzLoader FINISHED"
    date
    echo ""
    return 0
} # End NzEzLoader
