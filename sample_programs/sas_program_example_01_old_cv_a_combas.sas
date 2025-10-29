/*
************************************************************************ 
FILENAME :: sas_program_example_01_old_cv_a_combas.sas
************************************************************************ 
Author: Ye Wang  
Email: yew@wharton.upenn.edu 
Last Updated: 10/28/2025
 
This demo program includes an excerpt from an old CSMAR data-cleaning
SAS script cv_a_combas.sas (variable labeling code omitted for 
simplicity).
Historically, hundreds of similar manual programs were used to clean
CSMAR data before WRDS automated the process into a single SAS program.

*/  

/*
   The program includes a macro that generates SAS data set for 
   Balance Sheet-General Industry (Annual).

   The variable names and labels in the data step can be found in 
   the documentation file GTA_FS.doc

   input data:  

     fs_combas
     which is saved in lib raw_fs

   output data:

     combas 
     which is saved in lib o_f 
*/

/* 
  Note: 
  macro variables source_dataset, label, var_sort are defined at the 
  beginning of %macro cv_a_combas;
  libname raw_fs, o_f are defined in csmar_all.py, which runs 
  step08_cv_csmar_financial.sas from which %cv_a_combas is used.
*/                                                                           
%macro cv_a_combas;
    
    %let source_dataset=fs_combas;
    %let label=Balance Sheet-General Industry (Annual);
    %let var_sort=STKCD ACCPER TYPREP;
  
    data temp;
        set raw_fs.fs_combas;
        ACCPER=input(put(ACCPER,8.0),yymmdd8.);
        format ACCPER yymmddn8.;
        label
            A001000000 = "Total Assets"
            /* removed lines here to shorten the program for demo */
            ...

            Typrep = "Type Of Statements"
            ;
    run;
    
    proc sort data=temp out=o_f.combas nodupkey;
        by &var_sort;
    run;
    
    proc datasets library=o_f nolist;
        modify combas (label="&label");
        index create &var_sort;
    run;
    
%mend cv_a_combas;

