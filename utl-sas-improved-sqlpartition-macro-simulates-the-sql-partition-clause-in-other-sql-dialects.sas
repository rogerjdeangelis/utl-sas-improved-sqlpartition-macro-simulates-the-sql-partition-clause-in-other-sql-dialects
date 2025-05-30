%let pgm=utl-sas-improved-sqlpartition-macro-simulates-the-sql-partition-clause-in-other-sql-dialects;

%stop_submission;

Improved sqlpartition macro simulates the sql partition clause in other sql dialects

This also opens up some of the windows extensions in other sql dialects.
This may also help others sql programmers transition to sas?

 CONTENTS

 Easy to do in sqlite and sas datastep but not so easy in proc sql?

 Macro on end and in

 PURE PROC SQL CODE

  1 enumerate identical dup groups
  2 pivot wide
  3 pivot wide with sql arrays
  4 first 2 by sex age
  5 last 2 2 by sex age
  6 lag weight by sex and age
  7 cumulative sums by group
  8 add 1 to each sex age group
  9 sqlpartition macro

github
https://tinyurl.com/a7b3y6df
https://github.com/rogerjdeangelis/utl-sas-improved-sqlpartition-macro-simulates-the-sql-partition-clause-in-other-sql-dialects

%SOAPBOX ON;

The crux of the issue is that sas does not support 'order by' in a subquery.

THIS FAILS
==========

proc sql;
 select
     *
    ,momtonic() as record_number
 from
     (select * from sashelp,class order by sex)
;quit;

 (select * from sashelp,class order by sex)
                              -----
                              79
THE FIX

You have to be very careful how you use monotonic().
For instance I could never get it to work with a sas view.
If using a nested view, it appears that sas changes the odering after monotonic()


THIS WORKS (KINDA A BIG DEAL?) BASIS FOR SQL WINDOW EXTENSIONS
==============================================================

DOSUBL to the rescue, pre-sort at macro time using %dosubl.
This allow us to create a from clause with a embedded 'proc sql'
at macro time.

proc sql;
 create
     table seq_after_sort as
 select
     *
 from
     %dosubl('
        proc sql;  /*--- cannot use a view ---*/
          create
             table _have_ as
          select
             sex
            ,weight
         from
             sashelp.class(obs=5)
         order
             by sex, weight
     ')
     (select monotonic() as recnum,sex,weight from _have_)
;quit;

                               RECORD
 Obs    SEX    WEIGHT  NUMBERED BY SEX & WEIGHT

   1     F       84.0           1
   2     F       98.0           2
   3     F      102.5           3
   4     M      102.5           4
   5     M      112.5           5



%SOAPBOX OFF;

/**************************************************************************************************************************/
/*     INPUT            |                                                     |                                           */
/*     =====            |                                                     |                                           */
/*                      |                                                     | ***                                       */
/* SD1.HAVE obs=8       | 1 ENUMERATE SEX AGE                                 | SEQ SEX AGE WEIGHT                        */
/*                      | ======================                              |                                           */
/* SEX AGE WEIGHT       |                                                     |  1   F   13    71                         */
/*                      | proc sql;                                           |  2   F   13    86                         */
/*  M   11   115        |   create                                            |  3   F   13   124                         */
/*  M   11    83        |      table seqByGrp as                              |                                           */
/*  F   13    71        |   select                                            |  1   M   11    83                         */
/*  F   13    86        |      partition as seq                               |  2   M   11   115                         */
/*  F   13   124        |     ,sex                                            |                                           */
/*  M   14   120        |     ,age                                            |  1   M   14    74                         */
/*  M   14    74        |     ,weight                                         |  2   M   14    74                         */
/*  M   14    74        |   from                                              |  3   M   14   120                         */
/*                      |      %sqlpartition(                                 |                                           */
/* *RANDOM ORDER;       |        dsn=sd1.have                                 |                                           */
/*                      |       ,by=%str(sex,age)                             |                                           */
/* data sd1.have;       |       ,order=weight                                 |                                           */
/* input sex$           |       )                                             |                                           */
/*       age            | ;quit;                                              |                                           */
/*       weight;        |                                                     |                                           */
/* cards4;              |-------------------------------------------------------------------------------------------------*/
/* M 11 115             | 2 PIVOT WIDE WEIGHT                                 | SEX AGE WGT1 WGT2 WGT3                    */
/* F 13 071             | ==================                                  |                                           */
/* M 11 083             |                                                     |  F   13  71    86  124                    */
/* F 13 086             | proc sql;                                           |  M   11  83   115    .                    */
/* M 14 120             |   create                                            |  M   14  74    74  120                    */
/* M 14 074             |     table xpo as                                    |                                           */
/* F 13 124             |   select                                            |                                           */
/* M 14 074             |     sex                                             |                                           */
/* ;;;;                 |    ,age                                             |                                           */
/* run;quit;            |    ,max(case                                        |                                           */
/*                      |       when partition=1 then weight                  |                                           */
/*                      |       else . end) as wgt1                           |                                           */
/* JUST FOR CHECKING    |    ,max(case                                        |                                           */
/*                      |       when partition=2 then weight                  |                                           */
/* SEX AGE WEIGHT       |       else . end) as wgt2                           |                                           */
/*                      |    ,max(case                                        |                                           */
/*  F   13    71        |       when partition=3 then weight                  |                                           */
/*  F   13    86        |       else . end) as wgt3                           |                                           */
/*  F   13   124        |   from                                              |                                           */
/*                      |    %sqlpartition(                                   |                                           */
/*  M   11    83        |       dsn=sd1.have                                  |                                           */
/*  M   11   115        |      ,by=%str(sex,age)                              |                                           */
/*                      |      ,order=weight                                  |                                           */
/*  M   14    74        |      )                                              |                                           */
/*  M   14    74        |   group                                             |                                           */
/*  M   14   120        |     by sex, age                                     |                                           */
/*                      | ;quit;                                              |                                           */
/*                      |                                                     |                                           */
/*                      |-------------------------------------------------------------------------------------------------*/
/*                      | 3 PIVOT WIDE WITH SQL ARRAYS                        | SEX AGE WGT1 WGT2 WGT3                    */
/*                      | ============================                        |                                           */
/*                      |                                                     |  F   13  71    86  124                    */
/*                      | see below to get the 3 below                        |  M   11  83   115    .                    */
/*                      |                                                     |  M   14  74    74  120                    */
/*                      | %array(_cols,values=1-3);                           |                                           */
/*                      |                                                     |                                           */
/*                      | proc sql;                                           |                                           */
/*                      |  create                                             |                                           */
/*                      |    table xpo as                                     |                                           */
/*                      |  select                                             |                                           */
/*                      |    sex                                              |                                           */
/*                      |   ,age                                              |                                           */
/*                      |   ,%do_over(_cols,phrase=                           |                                           */
/*                      |     max(                                            |                                           */
/*                      |       case                                          |                                           */
/*                      |       when partition=?                              |                                           */
/*                      |        then weight else . end) as wgt?              |                                           */
/*                      |      ,between=comma)                                |                                           */
/*                      |  from                                               |                                           */
/*                      |   %sqlpartition(                                    |                                           */
/*                      |      dsn=sd1.have                                   |                                           */
/*                      |     ,by=%str(sex,age)                               |                                           */
/*                      |     ,order=weight                                   |                                           */
/*                      |     )                                               |                                           */
/*                      |  group                                              |                                           */
/*                      |    by sex, age                                      |                                           */
/*                      | ;quit;                                              |                                           */
/*                      |                                                     |                                           */
/*                      |-------------------------------------------------------------------------------------------------*/
/*                      | 4 FIRST 2 BY SEX AGE                                | FIRST 2                                   */
/*                      | ===================                                 |                                           */
/*                      |                                                     | SEQ SEX AGE WEIGHT                        */
/*                      |  proc sql;                                          |                                           */
/*                      |   create                                            |  1   F   13    71                         */
/*                      |      table first2 as                                |  2   F   13    86                         */
/*                      |   select                                            |                                           */
/*                      |      partition as seq                               |  1   M   11    83                         */
/*                      |     ,sex                                            |  2   M   11   115                         */
/*                      |     ,age                                            |                                           */
/*                      |     ,weight                                         |  1   M   14    74                         */
/*                      |   from                                              |  2   M   14    74                         */
/*                      |      %sqlpartition(                                 |                                           */
/*                      |        dsn=sd1.have                                 |                                           */
/*                      |       ,by=%str(sex,age)                             |                                           */
/*                      |       ,order=weight                                 |                                           */
/*                      |       )                                             |                                           */
/*                      |   where                                             |                                           */
/*                      |     partition <= 2                                  |                                           */
/*                      |  ;quit;                                             |                                           */
/*                      |                                                     |                                           */
/*                      |-------------------------------------------------------------------------------------------------*/
/*                      |  4 LAST 2 BY SEX AGE                                | LAST 2                                    */
/*                      |  ===================                                |                                           */
/*                      |                                                     | SEQ SEX AGE WEIGHT                        */
/*                      |  proc sql;                                          |                                           */
/*                      |   create                                            |  2   F   13    86  next to last           */
/*                      |      table last2 as                                 |  1   F   13   124  last                   */
/*                      |   select                                            |                                           */
/*                      |      partition as seq                               |  2   M   11    83                         */
/*                      |     ,sex                                            |  1   M   11   115                         */
/*                      |     ,age                                            |                                           */
/*                      |     ,weight                                         |  2   M   14    74                         */
/*                      |   from                                              |  1   M   14   120                         */
/*                      |      %sqlpartition(                                 |                                           */
/*                      |        dsn=sd1.have                                 |                                           */
/*                      |       ,minus=-1                                     |                                           */
/*                      |       ,by=%str(sex,age)                             |                                           */
/*                      |       ,order=weight                                 |                                           */
/*                      |       )                                             |                                           */
/*                      |   where                                             |                                           */
/*                      |       partition <=2                                 |                                           */
/*                      |   order                                             |                                           */
/*                      |       by sex, age, weight                           |                                           */
/*                      |  ;quit;                                             |                                           */
/*                      |                                                     |                                           */
/*                      |-------------------------------------------------------------------------------------------------*/
/*                      |  6 LAG WEIGHT BY SEX AND AGE                        | LAG1 WEIGHT                               */
/*                      |  ===========================                        |                                           */
/*                      |                                                     |                                           */
/*                      |  proc sql;                                          |                     LAG_                  */
/*                      |    create                                           | SEX AGE SEQ WEIGHT WEIGHT                 */
/*                      |        table want as                                |                                           */
/*                      |    select                                           |  F   13  1     71     .                   */
/*                      |        a.sex                                        |  F   13  2     86    71                   */
/*                      |       ,a.age                                        |  F   13  3    124    86                   */
/*                      |       ,a.partition as seq                           |  M   11  1     83     .                   */
/*                      |       ,a.weight                                     |  M   11  2    115    83                   */
/*                      |       ,b.weight as lag_weight                       |  M   14  1     74     .                   */
/*                      |    from                                             |  M   14  2     74    74                   */
/*                      |        %sqlpartition(                               |  M   14  3    120    74                   */
/*                      |          dsn=sd1.have                               |                                           */
/*                      |         ,by=%str(sex,age)                           |                                           */
/*                      |         ,order=weight                               |                                           */
/*                      |         )                  as a                     |                                           */
/*                      |    left join                                        |                                           */
/*                      |        %sqlpartition(                               |                                           */
/*                      |          dsn=sd1.have                               |                                           */
/*                      |         ,by=%str(sex,age)                           |                                           */
/*                      |         ,order=weight                               |                                           */
/*                      |         )                  as b                     |                                           */
/*                      |    on                                               |                                           */
/*                      |        a.sex = b.sex and                            |                                           */
/*                      |        a.age = b.age and                            |                                           */
/*                      |        a.partition = b.partition + 1                |                                           */
/*                      |    order                                            |                                           */
/*                      |        by a.sex,a.age, a.partition;                 |                                           */
/*                      |  quit;                                              |                                           */
/*                      |                                                     |                                           */
/*                      |-------------------------------------------------------------------------------------------------*/
/*                      |  7 CUMULATIVE SUMS BY GROUP                         |                              CUM          */
/*                      |  ==========================                         | SEX    AGE    N    WEIGHT    WGT          */
/*                      |                                                     |                                           */
/*                      |  proc sql;                                          |  F      13    1       71      71          */
/*                      |                                                     |  F      13    2       86     157          */
/*                      |    /*---- cannnot use view? ----*/                  |  F      13    3      124     281          */
/*                      |    create                                           |                                           */
/*                      |       table havex as                                |  M      11    4       83      83          */
/*                      |    select                                           |  M      11    5      115     198          */
/*                      |      monotonic() as n                               |                                           */
/*                      |      ,(partition=1) as firsts                       |  M      14    6       74      74          */
/*                      |      ,sex                                           |  M      14    7       74     148          */
/*                      |      ,age                                           |  M      14    8      120     268          */
/*                      |      ,weight                                        |                                           */
/*                      |       /*-- should here --*/                         |                                           */
/*                      |    from                                             |                                           */
/*                      |       %sqlpartition(                                |                                           */
/*                      |         dsn=sd1.have                                |                                           */
/*                      |        ,by=%str(sex,age)                            |                                           */
/*                      |        ,order=weight                                |                                           */
/*                      |        )                                            |                                           */
/*                      |  ;                                                  |                                           */
/*                      |    create                                           |                                           */
/*                      |        table want as                                |                                           */
/*                      |    select                                           |                                           */
/*                      |        a.sex                                        |                                           */
/*                      |       ,a.age                                        |                                           */
/*                      |       ,a.n                                          |                                           */
/*                      |       ,a.weight                                     |                                           */
/*                      |       ,sum(b.weight) as wgt                         |                                           */
/*                      |    from                                             |                                           */
/*                      |        havex a inner join havex b                   |                                           */
/*                      |    on                                               |                                           */
/*                      |        b.n  <= a.n and                              |                                           */
/*                      |        a.sex = b.sex and                            |                                           */
/*                      |        a.age = b.age                                |                                           */
/*                      |    group                                            |                                           */
/*                      |        by a.sex,a.age,a.n,a.weight                  |                                           */
/*                      |    order                                            |                                           */
/*                      |        by a.sex,a.age, a.n;                         |                                           */
/*                      |  quit;                                              |                                           */
/*                      |                                                     |                                           */
/*                      |-------------------------------------------------------------------------------------------------*/
/*                      |  8 ADD 1 TO EACH SEX AGE GROUP                      |                                           */
/*                      |  =============================                      |  ROWNUM SEX AGE WEIGHT N                  */
/*                      |                                                     |                                           */
/*                      |  proc sql;                                          |     1    F   13    71  1                  */
/*                      |    create                                           |     0    F   13    86  2                  */
/*                      |       table havex as                                |     0    F   13   124  3                  */
/*                      |    select                                           |     1    M   11    83  4                  */
/*                      |      monotonic() as n                               |     0    M   11   115  5                  */
/*                      |      ,(partition=1) as firsts                       |     1    M   14    74  6                  */
/*                      |      ,sex                                           |     0    M   14    74  7                  */
/*                      |      ,age                                           |     0    M   14   120  8                  */
/*                      |      ,weight                                        |                                           */
/*                      |       /*-- should here --*/                         |  JUST CUM ROWNUM                          */
/*                      |    from                                             |                                           */
/*                      |       %sqlpartition(                                |   SEX AGE WEIGHT GROUP                    */
/*                      |         dsn=sd1.have                                |                                           */
/*                      |        ,by=%str(sex,age)                            |    F   13    71    1                      */
/*                      |        ,order=weight                                |    F   13    86    1                      */
/*                      |        )                                            |    F   13   124    1                      */
/*                      |    ;                                                |                                           */
/*                      |    create                                           |    M   11    83    2                      */
/*                      |      table want as                                  |    M   11   115    2                      */
/*                      |    select                                           |                                           */
/*                      |      l.sex                                          |    M   14    74    3                      */
/*                      |     ,l.age                                          |    M   14    74    3                      */
/*                      |     ,l.weight                                       |    M   14   120    3                      */
/*                      |     ,r.add1 as group                                |                                           */
/*                      |    from                                             |                                           */
/*                      |      have as l left join inr as r                   |                                           */
/*                      |    on                                               |                                           */
/*                      |      l.sex=r.sex and                                |                                           */
/*                      |      l.age = r.age                                  |                                           */
/*                      |    group by l.sex, l.weight                         |                                           */
/*                      |    order                                            |                                           */
/*                      |      by n                                           |                                           */
/*                      |  ;quit;                                             |                                           */
/**************************************************************************************************************************/

/*                   _
(_)_ __  _ __  _   _| |_
| | `_ \| `_ \| | | | __|
| | | | | |_) | |_| | |_
|_|_| |_| .__/ \__,_|\__|
        |_|
*/

/*--- USEFUL DURING DEVELOPMENT ----*/

proc datasets lib=work
 nolist nodetails ;
 delete sasmac1 sasmac2 sasmac3 /  mt=cat;
 delete _have_ dupgroups xpo;
run;quit;

proc catalog catalog=work.sasmacr;
 delete sqlpartition / et=macro;
run;quit;

%symdel res order / nowarn;


*RANDOM ORDER;

data sd1.have;
input sex$
      age
      weight;
cards4;
M 11 115
F 13 071
M 11 083
F 13 086
M 14 120
M 14 074
F 13 124
M 14 074
;;;;
run;quit;

/**************************************************************************************************************************/
/* SEX    AGE    WEIGHT                                                                                                   */
/*                                                                                                                        */
/*  M      11      115                                                                                                    */
/*  F      13       71                                                                                                    */
/*  M      11       83                                                                                                    */
/*  F      13       86                                                                                                    */
/*  M      14      120                                                                                                    */
/*  M      14       74                                                                                                    */
/*  F      13      124                                                                                                    */
/*  M      14       74                                                                                                    */
/**************************************************************************************************************************/

/*                                         _
/ |   ___ _ __  _   _ _ __   ___ _ __ __ _| |_ ___   ___  _____  __
| |  / _ \ `_ \| | | | `_ \ / _ \ `__/ _` | __/ _ \ / __|/ _ \ \/ /
| | |  __/ | | | |_| | | | |  __/ | | (_| | ||  __/ \__ \  __/>  <
|_|  \___|_| |_|\__,_|_| |_|\___|_|  \__,_|\__\___| |___/\___/_/\_\
*/
 proc sql;
   create
      table seqByGrp as
   select
      partition as seq
     ,sex
     ,age
     ,weight
   from
      %sqlpartition(
        dsn=sd1.have
       ,by=%str(sex,age)
       ,order=weight
       )
 ;quit;

/**************************************************************************************************************************/
/*  SEQ    SEX    AGE    WEIGHT                                                                                           */
/*                                                                                                                        */
/*   1      F      13       71                                                                                            */
/*   2      F      13       86                                                                                            */
/*   3      F      13      124                                                                                            */
/*   1      M      11       83                                                                                            */
/*   2      M      11      115                                                                                            */
/*   1      M      14       74                                                                                            */
/*   2      M      14       74                                                                                            */
/*   3      M      14      120                                                                                            */
/**************************************************************************************************************************/
/*___          _            _              _     _            _       _
|___ \   _ __ (_)_   _____ | |_  __      _(_) __| | ___    __| | __ _| |_ ___
  __) | | `_ \| \ \ / / _ \| __| \ \ /\ / / |/ _` |/ _ \  / _` |/ _` | __/ _ \
 / __/  | |_) | |\ V / (_) | |_   \ V  V /| | (_| |  __/ | (_| | (_| | ||  __/
|_____| | .__/|_| \_/ \___/ \__|   \_/\_/ |_|\__,_|\___|  \__,_|\__,_|\__\___|
        |_|
*/

 proc sql;
   create
     table xpo as
   select
     sex
    ,age
    ,max(case
       when partition=1 then weight
       else . end) as wgt1
    ,max(case
       when partition=2 then weight
       else . end) as wgt2
    ,max(case
       when partition=3 then weight
       else . end) as wgt3
   from
    %sqlpartition(
       dsn=sd1.have
      ,by=%str(sex,age)
      ,order=weight
      )
   group
     by sex, age
 ;quit;

/**************************************************************************************************************************/
/*  SEX    AGE    WGT1    WGT2    WGT3                                                                                    */
/*                                                                                                                        */
/*   F      13     71       86     124                                                                                    */
/*   M      11     83      115       .                                                                                    */
/*   M      14     74       74     120                                                                                    */
/**************************************************************************************************************************/

/*____         _            _              _     _                  _
|___ /   _ __ (_)_   _____ | |_  __      _(_) __| | ___   ___  __ _| |  __ _ _ __ _ __ __ _ _   _ ___
  |_ \  | `_ \| \ \ / / _ \| __| \ \ /\ / / |/ _` |/ _ \ / __|/ _` | | / _` | `__| `__/ _` | | | / __|
 ___) | | |_) | |\ V / (_) | |_   \ V  V /| | (_| |  __/ \__ \ (_| | || (_| | |  | | | (_| | |_| \__ \
|____/  | .__/|_| \_/ \___/ \__|   \_/\_/ |_|\__,_|\___| |___/\__, |_| \__,_|_|  |_|  \__,_|\__, |___/
        |_|                                                      |_|                        |___/
*/

 %array(_cols,values=1-3);

 proc sql;
  create
    table xpo as
  select
    sex
   ,age
   ,%do_over(_cols,phrase=
     max(
       case
       when partition=?
        then weight else . end) as wgt?
      ,between=comma)
  from
   %sqlpartition(
      dsn=sd1.have
     ,by=%str(sex,age)
     ,order=weight
     )
  group
    by sex, age
 ;quit;

/**************************************************************************************************************************/
/* SEX    AGE    WGT1    WGT2    WGT3                                                                                     */
/*                                                                                                                        */
/*  F      13     71       86     124                                                                                     */
/*  M      11     83      115       .                                                                                     */
/*  M      14     74       74     120                                                                                     */
/**************************************************************************************************************************/

/*  _      __ _          _     ____    _
| || |    / _(_)_ __ ___| |_  |___ \  | |__  _   _   ___  _____  __   __ _  __ _  ___
| || |_  | |_| | `__/ __| __|   __) | | `_ \| | | | / __|/ _ \ \/ /  / _` |/ _` |/ _ \
|__   _| |  _| | |  \__ \ |_   / __/  | |_) | |_| | \__ \  __/>  <  | (_| | (_| |  __/
   |_|   |_| |_|_|  |___/\__| |_____| |_.__/ \__, | |___/\___/_/\_\  \__,_|\__, |\___|
                                             |___/                         |___/
*/

 proc sql;
  create
     table first2 as
  select
     partition as seq
    ,sex
    ,age
    ,weight
  from
     %sqlpartition(
       dsn=sd1.have
      ,by=%str(sex,age)
      ,order=weight
      )
  where
    partition <= 2
 ;quit;

 /**************************************************************************************************************************/
 /*  SEQ    SEX    AGE    WEIGHT                                                                                           */
 /*                                                                                                                        */
 /*   1      F      13       71                                                                                            */
 /*   2      F      13       86                                                                                            */
 /*   1      M      11       83                                                                                            */
 /*   2      M      11      115                                                                                            */
 /*   1      M      14       74                                                                                            */
 /*   2      M      14       74                                                                                            */
 /**************************************************************************************************************************/

/*___    _           _     ____    ____    _
| ___|  | | __ _ ___| |_  |___ \  |___ \  | |__  _   _   ___  _____  __   __ _  __ _  ___
|___ \  | |/ _` / __| __|   __) |   __) | | `_ \| | | | / __|/ _ \ \/ /  / _` |/ _` |/ _ \
 ___) | | | (_| \__ \ |_   / __/   / __/  | |_) | |_| | \__ \  __/>  <  | (_| | (_| |  __/
|____/  |_|\__,_|___/\__| |_____| |_____| |_.__/ \__, | |___/\___/_/\_\  \__,_|\__, |\___|
                                                 |___/                         |___/
*/

  proc sql;
   create
      table last2 as
   select
      partition as seq
     ,sex
     ,age
     ,weight
   from
      %sqlpartition(
        dsn=sd1.have
       ,minus=-1
       ,by=%str(sex,age)
       ,order=weight
       )
   where
       partition <=2
   order
       by sex, age, weight
  ;quit;

/**************************************************************************************************************************/
/*  SEQ    SEX    AGE    WEIGHT                                                                                           */
/*                                                                                                                        */
/*   2      F      13       86                                                                                            */
/*   1      F      13      124                                                                                            */
/*   2      M      11       83                                                                                            */
/*   1      M      11      115                                                                                            */
/*   2      M      14       74                                                                                            */
/*   1      M      14      120                                                                                            */
/**************************************************************************************************************************/

/*__     _                            _       _     _     _
 / /_   | | __ _  __ _  __      _____(_) __ _| |__ | |_  | |__  _   _  ___  _____  __   __ _  __ _  ___
| `_ \  | |/ _` |/ _` | \ \ /\ / / _ \ |/ _` | `_ \| __| | `_ \| | | |/ __|/ _ \ \/ /  / _` |/ _` |/ _ \
| (_) | | | (_| | (_| |  \ V  V /  __/ | (_| | | | | |_  | |_) | |_| |\__ \  __/>  <  | (_| | (_| |  __/
 \___/  |_|\__,_|\__, |   \_/\_/ \___|_|\__, |_| |_|\__| |_.__/ \__, ||___/\___/_/\_\  \__,_|\__, |\___|
                 |___/                  |___/                   |___/                        |___/
*/

 proc sql;
   create
       table want as
   select
       a.sex
      ,a.age
      ,a.partition as seq
      ,a.weight
      ,b.weight as lag_weight
   from
       %sqlpartition(
         dsn=sd1.have
        ,by=%str(sex,age)
        ,order=weight
        )                  as a
   left join
       %sqlpartition(
         dsn=sd1.have
        ,by=%str(sex,age)
        ,order=weight
        )                  as b
   on
       a.sex = b.sex and
       a.age = b.age and
       a.partition = b.partition + 1
   order
       by a.sex,a.age, a.partition;
 quit;

/**************************************************************************************************************************/
/*                                  LAG_                                                                                  */
/*  SEX    AGE    SEQ    WEIGHT    WEIGHT                                                                                 */
/*                                                                                                                        */
/*   F      13     1        71        .                                                                                   */
/*   F      13     2        86       71                                                                                   */
/*   F      13     3       124       86                                                                                   */
/*   M      11     1        83        .                                                                                   */
/*   M      11     2       115       83                                                                                   */
/*   M      14     1        74        .                                                                                   */
/*   M      14     2        74       74                                                                                   */
/*   M      14     3       120       74                                                                                   */
/**************************************************************************************************************************/

/*____                                                    _
|___  |   ___ _   _ _ __ ___    ___ _   _ _ __ ___  ___  | |__  _   _  ___  _____  __   __ _  __ _  ___
   / /   / __| | | | `_ ` _ \  / __| | | | `_ ` _ \/ __| | `_ \| | | |/ __|/ _ \ \/ /  / _` |/ _` |/ _ \
  / /   | (__| |_| | | | | | | \__ \ |_| | | | | | \__ \ | |_) | |_| |\__ \  __/>  <  | (_| | (_| |  __/
 /_/     \___|\__,_|_| |_| |_| |___/\__,_|_| |_| |_|___/ |_.__/ \__, ||___/\___/_/\_\  \__,_|\__, |\___|
                                                                |___/                        |___/
*/

 proc sql;

   /*---- cannnot use view? ----*/
   create
      table havex as
   select
     monotonic() as n
     ,(partition=1) as firsts
     ,sex
     ,age
     ,weight
      /*-- should here --*/
   from
      %sqlpartition(
        dsn=sd1.have
       ,by=%str(sex,age)
       ,order=weight
       )
 ;
   create
       table want as
   select
       a.sex
      ,a.age
      ,a.n
      ,a.weight
      ,sum(b.weight) as wgt
   from
       havex a inner join havex b
   on
       b.n  <= a.n and
       a.sex = b.sex and
       a.age = b.age
   group
       by a.sex,a.age,a.n,a.weight
   order
       by a.sex,a.age, a.n;
 quit;

/**************************************************************************************************************************/
/* WORK.WANT                                                                                                              */
/*   N    FIRSTS    SEX    AGE    WEIGHT                                                                                  */
/*                                                                                                                        */
/*   1       1       F      13       71                                                                                   */
/*   2       0       F      13       86                                                                                   */
/*   3       0       F      13      124                                                                                   */
/*   4       1       M      11       83                                                                                   */
/*   5       0       M      11      115                                                                                   */
/*   6       1       M      14       74                                                                                   */
/*   7       0       M      14       74                                                                                   */
/*   8       0       M      14      120                                                                                   */
/**************************************************************************************************************************/
/*___              _     _   _   _                          _
 ( _ )    __ _  __| | __| | / | | |_ ___     ___  __ _  ___| |__    __ _ _ __ ___  _   _ _ __
 / _ \   / _` |/ _` |/ _` | | | | __/ _ \   / _ \/ _` |/ __| `_ \  / _` | `__/ _ \| | | | `_ \
| (_) | | (_| | (_| | (_| | | | | || (_) | |  __/ (_| | (__| | | || (_| | | | (_) | |_| | |_) |
 \___/   \__,_|\__,_|\__,_| |_|  \__\___/   \___|\__,_|\___|_| |_| \__, |_|  \___/ \__,_| .__/
                                                                   |___/                |_|
*/

proc sql;
  create
     table havex as
  select
    monotonic() as n
    ,(partition=1) as firsts
    ,sex
    ,age
    ,weight
     /*-- should here --*/
  from
     %sqlpartition(
       dsn=sd1.have
      ,by=%str(sex,age)
      ,order=weight
      )
  ;
  create
    table want as
  select
    l.sex
   ,l.age
   ,l.weight
   ,r.add1 as group
  from
    have as l left join inr as r
  on
    l.sex=r.sex and
    l.age = r.age
  group by l.sex, l.weight
  order
    by n
;quit;

/**************************************************************************************************************************/
/* WORK.WANT                                                                                                              */
/*  SEX    AGE    WEIGHT    GROUP                                                                                         */
/*                                                                                                                        */
/*   F      13       71       1                                                                                           */
/*   F      13       86       1                                                                                           */
/*   F      13      124       1                                                                                           */
/*   M      11       83       2                                                                                           */
/*   M      11      115       2                                                                                           */
/*   M      14       74       3                                                                                           */
/*   M      14       74       3                                                                                           */
/*   M      14      120       3                                                                                           */
/**************************************************************************************************************************/

/*___              _                  _   _ _   _
 / _ \   ___  __ _| |_ __   __ _ _ __| |_(_) |_(_) ___  _ __   _ __ ___   __ _  ___ _ __ ___
| (_) | / __|/ _` | | `_ \ / _` | `__| __| | __| |/ _ \| `_ \ | `_ ` _ \ / _` |/ __| `__/ _ \
 \__, | \__ \ (_| | | |_) | (_| | |  | |_| | |_| | (_) | | | || | | | | | (_| | (__| | | (_) |
   /_/  |___/\__, |_| .__/ \__,_|_|   \__|_|\__|_|\___/|_| |_||_| |_| |_|\__,_|\___|_|  \___/
                |_| |_|
*/

/*---- save in autocall library ----*/
filename ft15f001 "c:/oto/sqlpartition.sas";
parmcards4;
%macro sqlpartition(dsn=,by=team,minus=1,order=) /
   des="Improved sqlpartition that maintains data order";

 %local res;

 %put %sysfunc(ifc(%sysevalf(%superq(dsn )=,boolean),**** Please provide input dataset  ****,));
 %put %sysfunc(ifc(%sysevalf(%superq(by  )=,boolean),**** Please provide by variables ****,));

 %let res= %eval
 (
     %sysfunc(ifc(%sysevalf(%superq(dsn )=,boolean),1,0))
   + %sysfunc(ifc(%sysevalf(%superq(by )=,boolean),1,0))
 );

  %if &res = 0 %then %do;

     %if "&order" ^= "" %then %do;
       %let order=%str(,&order);
     %end;

     (select
       *
      ,seq-min(seq) + 1 as partition
     from
        %dosubl('
           proc sql;
            create
              table _have_ as
            select
              *
           from
              &dsn
           order
            by &by &order
     ;quit;' )
     (select
        *
        ,&minus*monotonic() as seq
     from
         _have_)
     group
        by &by)

  %end;

%mend sqlpartition;
;;;;
run;quit;

/*              _
  ___ _ __   __| |
 / _ \ `_ \ / _` |
|  __/ | | | (_| |
 \___|_| |_|\__,_|

*/
