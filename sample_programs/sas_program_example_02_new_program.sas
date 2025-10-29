/*
************************************************************************ 
FILENAME :: sas_program_example_02_new_program.sas
************************************************************************ 
Author: Ye Wang  
Email: yew@wharton.upenn.edu 
Last Updated: 10/28/2025
 
This program is for demo only.

It is an excerpt from clean_csmar_compressed_sas_datasets.sas

It is the new program that replaces hundreds of old CSMAR data cleaning
programs.  

*/  

/*
************************************************************************ 
FILENAME :: clean_csmar_compressed_sas_datasets.sas
************************************************************************ 
Author: Ye Wang  
Email: yew@wharton.upenn.edu 
Last Updated: 10/28/2025
 
Note!!!
This program contains Chinese characters. We need to edit it in 
Notepad++ with encoding UTF-8 (no BOM).

This program cleans CSMAR compressed SAS datasets by using the 
information in the data vendor provided .xlsx file (data dictionary +
database changes information in this update, which contains Chinese 
characters).  

It includes the following steps:

1)
reads in the Excel-format data dictionary file provided by CSMAR
to generate two data dictionary SAS datasets:
1.1)  rawsas.csmar_dd_at_table_level
1.2)  rawsas.csmar_dd_at_variable_level

2) 
uses rawsas.csmar_dd_at_table_level and rawsas.csmar_dd_at_variable_level
to write an output SAS program 
autogen_csmar_data_cleaning_program_&current_year.sas to clean
CSMAR compressed SAS datasets (the datasets that were converted from
Sqlserver tables and are mentioned in the Excel format data dictionary
file) one by one

the cleaning includes:
    a) converts the date variables from 8. or string into YYMMDDN8. format
       sets special missing values
       creates &curr_important_datevar._str to store the complete info
       in &curr_important_datevar. 
    b) sorts the data by primary keys, compresses char
    c) adds data set label, variable labels, creates indexes

3)
runs autogen_csmar_data_cleaning_program_&current_year.sas to clean
the CSMAR compressed SAS datasets

Required Scripts: 
    csmar_all.py (defines &current_year)

input data:

    /wrds/csmar/official_docs/for_&current_year._update/
    CSMAR*_for_WRDS_data_dictionary_w_stats_*.xlsx
    (the data dictionary file from CSMAR, must be saved in .xlsx format
     for this program to read in)
    example: /wrds/csmar/official_docs/for_2025_update/
             CSMAR2024_for_WRDS_data_dictionary_w_stats_20250618.xlsx
    
    raw CSMAR SAS datasets (converted from the SqlServer tables) in
    /wrds/csmar/rawdata/&current_year/extracted/&cur_sub_database
    /sqlserver_into_sas/compressed/*.sas7bdat";

output:
    intermediate output:
        rawsas.csmar_dd_at_table_level
        rawsas.csmar_dd_at_variable_level

        /wrds/csmar/logs/autogen_csmar_data_cleaning_program_&current_year.sas

    final output:
        /wrds/csmar/sasdata/(csmar subproduct folder)/*.sas7bdat

*/
*options mprint mlogic symbolgen;

/* 
  If we run this program from csmar_all.py, need to remove this line and set current_year
  in csmar_all.py 

  *%let current_year = 2025;
*/
%let output_autogen_sas_program = /wrds/csmar/logs/autogen_csmar_data_cleaning_program_&current_year..sas;

%include './sasautos/nwords.sas';

libname rawsas '/wrds/csmar/rawsasdata/';

/*
    1)
    reads in the Excel-format data dictionary file provided by CSMAR
    to generate two data dictionary SAS datasets:
    1.1)  rawsas.csmar_dd_at_table_level
    1.2)  rawsas.csmar_dd_at_variable_level
*/
/*
    note: 
    we have to save the Excel file provided by CSMAR as an .xlsx format data.
    Linux SAS cannot handle .xls format data.
*/ 
libname dd xlsx "/wrds/csmar/official_docs/for_&current_year._update/CSMAR*_for_WRDS_data_dictionary_w_stats_*.xlsx";

/*
    1.1) creates rawsas.csmar_dd_at_table_level
*/
 
data csmar_dd_table_level;
    set dd.统计信息;
    /*
      I removed code here to simplify this example code
    */
    ...                
run;
    
data rawsas.csmar_dd_table_level;
    /* changes length, format, informat to prevent truncation */
    length product_name $15 
           libname_path_for_output_ds $150
           libname_path_for_source_ds $150
           output_subfolder_name $18
           source_subfolder_name $34
           important_datevar $30;
    /*
       must modify the format and the informat to prevent the
       values read in from being truncated
    */
    format product_name $15.;
    informat product_name $15.;
    format important_datevar $30.;
    informat important_datevar $30.;

    set csmar_dd_table_level;

    /*
      I removed code here to simplify this example code
    */
    ...  
run;


/*
    1.2) creates rawsas.csmar_dd_at_variable_level
*/
data rawsas.csmar_dd_at_variable_level;
    set dd.字段信息;
    /*
      I removed code here to simplify this example code
    */
    ...  
    keep dbname topictitle tbname fldname title_en descn_en;
run;


/*
    2) 
    uses rawsas.csmar_dd_at_table_level and rawsas.csmar_dd_at_variable_level
    to write an output SAS program 
    autogen_csmar_data_cleaning_program_&current_year.sas that cleans
    CSMAR compressed SAS datasets (the datasets that were converted from
    Sqlserver tables and are mentioned in the Excel format data dictionary
    file) one by one

    the cleaning includes:
        a) converts the date variables from 8. or string into YYMMDDN8. format
           sets special missing values
           creates &curr_important_datevar._str to store the complete info
           in &curr_important_datevar. 
        b) sorts the data by primary keys
        c) adds data set label, variable labels, creates indexes
*/

%macro generates_sas_clean_program;

    /*
      get table level information and save them into macro variables
    */
    proc sql noprint;
        select dataset_name,
               dataset_label,
               important_datevar,
               primary_keys,
               libname_path_for_source_ds,
               libname_path_for_output_ds 
        into :list_dataset_name separated by '~',
             :list_dataset_label separated by '~',
             :list_important_datevar separated by '~',
             :list_primary_keys separated by '~',
             :list_path_for_source_ds separated by '~',
             :list_path_for_output_ds separated by '~'
        from rawsas.csmar_dd_table_level;
    quit;

    %put macro variable list_dataset_name = &list_dataset_name;
    %put macro variable list_dataset_label = &list_dataset_label;
    %put macro variable list_important_datevar = &list_important_datevar;
    %put macro variable list_primary_keys = &list_primary_keys;
    %put macro variable list_path_for_source_ds = &list_path_for_source_ds;
    %put macro variable list_path_for_output_ds = &list_path_for_output_ds;

    /* outputs to the top of the output SAS program */
    data _null_;
        file "&output_autogen_sas_program";
        put "*This program is generated by clean_csmar_compressed_sas_datasets.sas;";
        put;
        put '%macro cleans_csmar_compressed_sas_ds;';
    run;


    /*
       outputs the data cleaning code for each dataset, appending the code to 
       the output SAS program using mod in the file statement
    */
    %do iterator = 1 %to %sysfunc(countw(&list_dataset_name, '~'));

        %let curr_dataset_name = %scan(&list_dataset_name, &iterator, '~');
        %let curr_dataset_label = %scan(&list_dataset_label, &iterator, '~');
        %let curr_important_datevar = %scan(&list_important_datevar, &iterator, '~');
        %let curr_primary_keys = %scan(&list_primary_keys, &iterator, '~');
        %let curr_path_for_source_ds = %scan(&list_path_for_source_ds, &iterator, '~');
        %let curr_path_for_output_ds = %scan(&list_path_for_output_ds, &iterator, '~');

        data _null_;
            file "&output_autogen_sas_program" mod;
            put;

            put;
            put "   libname source ""&curr_path_for_source_ds"";";
            put "   libname output ""&curr_path_for_output_ds"";";
            put;
            put "        /* removes data file and index file before creating any new files to avoid warnings */ ";  
            put "        x 'rm -fv &curr_path_for_output_ds.&curr_dataset_name..sas7bndx';";
            put "        x 'rm -fv &curr_path_for_output_ds.&curr_dataset_name..sas7bdat';";
            put;
            put "        /* converts char type important date variable &curr_important_datevar.  ";
            put "           into numeric format if there is any.";
            put "           creates a new string variable &curr_important_datevar._str to store  ";
            put "           the complete info in &curr_important_datevar. ";
            put "           note: datasets with important date variables that are year, month or ";
            put "                 week variables have important_datevar set to                   ";
            put "                 'no_important_datevar' in rawsas.csmar_dd_table_level.         ";
            put "                 So, we do not need to treat them as date variables here.       ";
            put "           converts important date variables from 8. to YYMMDDN8., ";
            put "           Some parts of the dates may be missing and set to 00, SAS will not   ";
            put "           be able to save them as date variables.";
            put "           To solve this problem, we will replace those missing dates as:";
            put "               .N  if the original value is 0,                               ";
            put "               .Y  if the year is missing in the original value              ";
            put "               .M  if the month is missing in the original value             ";
            put "               .D  if the day is missing in the original value               ";
            put "           a temporary variable &curr_important_datevar._new is used.    ";
            put "        */ ";            
            put "        data temp;";
            put "            set source.&curr_dataset_name;";
            put "            %if ""&curr_important_datevar"" ne ""no_important_datevar""";
            put "            %then %do;";
            put "                if vtype(&curr_important_datevar.) = 'C' then do;";
            put "                    *create &curr_important_datevar._str;";
            put "                    &curr_important_datevar._str = compress(&curr_important_datevar., '- ');";
            put "                end;";
            put "                else if vtype(&curr_important_datevar.) = 'N' then do;";
            put "                    &curr_important_datevar._str = cats('',&curr_important_datevar.);";
            put "                end;";
            put "                yy = substr(&curr_important_datevar._str, 1, 4);";
            put "                mm = substr(&curr_important_datevar._str, 5, 2);";
            put "                dd = substr(&curr_important_datevar._str, 7, 2);";
            put "                *create &curr_important_datevar._new from &curr_important_datevar._str;";
            put "                if &curr_important_datevar._str = '0' then &curr_important_datevar._new = .N;";
            put "                else if yy = '0000' then &curr_important_datevar._new = .Y;";
            put "                else if mm = '00' then &curr_important_datevar._new = .M;";
            put "                else if dd = '00' then &curr_important_datevar._new = .D;";
            put "                else &curr_important_datevar._new = input(&curr_important_datevar._str,yymmdd8.);";
            put "                drop yy mm dd; ";                       
            put "                drop &curr_important_datevar.;";
            put "                format &curr_important_datevar._new yymmddn8.;";  
            put "                label &curr_important_datevar._str = ""str format of &curr_important_datevar. (added by WRDS)"";";            
            put "                rename &curr_important_datevar._new = &curr_important_datevar.;";
            put "            %end;";
            put "        run;";
            put;
            put "        /* sorts data by primary keys, compresses char */ "; 
            put "        proc sort data=temp out=output.&curr_dataset_name(compress=char) force;";
            put "            by &curr_primary_keys;";
            put "        run;";
            put;         

            put "        /* adds dataset label, indexes on primary keys, adds variable labels */ "; 
            put "        proc datasets library=output nolist;";
            put "            modify &curr_dataset_name (label=""&curr_dataset_label"");";
            put "            index create &curr_primary_keys;";
            put "            label"; 
        run;

        data _null_;
            file "&output_autogen_sas_program" mod;
            /* adds variable labels */
            set rawsas.csmar_dd_at_variable_level;
            where dataset_name = "&curr_dataset_name";
            put "                " varname "= " ""varlabel"";
        run;

        data _null_;
            file "&output_autogen_sas_program" mod;
            put "            ;";
            put "        quit;";
            put;
        run;
    %end;

    data _null_;
        file "&output_autogen_sas_program" mod;
        put;
        put'%mend cleans_csmar_compressed_sas_ds;';
        put;
        put'%cleans_csmar_compressed_sas_ds;';
        put;
    run;

%mend generates_sas_clean_program;

%generates_sas_clean_program

/*
  3)
    runs autogen_csmar_data_cleaning_program_&current_year.sas to clean
    the CSMAR compressed SAS datasets
*/    
%include "&output_autogen_sas_program";








