 IDENTIFICATION DIVISION.
 PROGRAM-ID. EXECQUERYGETRECORDS.

 ENVIRONMENT DIVISION.

 DATA DIVISION.
 WORKING-STORAGE SECTION.

 01 GRAAL_CREATE_ISOLATE_PARAMS_T.
    03 VERSION-1                        USAGE BINARY-LONG.
    03 RESERVED-ADDRESS-SPACE-SIZE      USAGE BINARY-DOUBLE.
    03 AUXILIARY-IMAGE-PATH             USAGE BINARY-CHAR.
    03 AUXILIARY-IMAGE-RESERVED-SPACE-SIZE 
                                        USAGE BINARY-DOUBLE.

 01 GRAAL_ISOLATE_T                      USAGE POINTER.
 01 GRAAL_ISOLATETHREAD_T                USAGE POINTER.
 01 RESPONSE                             USAGE BINARY-LONG.
 01 RESULT                               USAGE BINARY-LONG.
 01 URI                                  PIC X(50).
 01 USER                                 PIC X(20).
 01 PWD                                  PIC X(20).
 01 QUERY                                PIC X(200).

  01 CUS BASED.
      05 CUS-STRUCT OCCURS 20.   
       10 CUS-ID                          USAGE BINARY-DOUBLE.
       10 CUS-NAME-PTR                    USAGE POINTER.
       10 CUS-AGE                         USAGE BINARY-DOUBLE.


 01 CUS-POINTER                           USAGE POINTER.
 01 CUS-NAME-ADDR                         PIC X(20) BASED.

  01 CUS-TITLE-DISPLAY.
       05 FILLER                          PIC X(4) VALUE '  ID'.
       05 FILLER                          PIC X(5).
       05 FILLER                          PIC X(20) VALUE 'NAME'.
       05 FILLER                          PIC X(5).
       05 FILLER                          PIC X(3) VALUE 'AGE'.
 01 CUS-SUB-DISPLAY.
       05 FILLER                          PIC X(4) VALUE '----'.
       05 FILLER                          PIC X(5).
       05 FILLER                          PIC X(20) VALUE '--------------------'.
       05 FILLER                          PIC X(5).
       05 FILLER                          PIC X(3) VALUE '---'.      
 01 CUS-DISPLAY.
       05 CUS-ID-DIS                      PIC ZZZ9.
       05 FILLER                          PIC X(5).
       05 CUS-NAME-DIS                    PIC X(20).
       05 FILLER                          PIC X(5).
       05 CUS-AGE-DIS                     PIC ZZ9.
 
 01    I                                   PIC 9(2).


 PROCEDURE DIVISION.

*>----------------------------------------------------------------------
 MAIN-EXECQUERYGETRECORDS SECTION.
*>----------------------------------------------------------------------
    
    CALL STATIC 'graal_create_isolate' using
           BY REFERENCE GRAAL_CREATE_ISOLATE_PARAMS_T
           BY REFERENCE GRAAL_ISOLATE_T
           BY REFERENCE GRAAL_ISOLATETHREAD_T 
           returning RESPONSE
    END-CALL

    IF RESPONSE equal 0 then
       MOVE Z'jdbc:postgresql://localhost:5432/testdb'  TO URI
       MOVE Z'postgres'                      TO USER
       MOVE Z'postgres'                      TO PWD
       MOVE Z'SELECT CUS_ID, CUS_NAME, CUS_AGE FROM CUS ORDER BY CUS_AGE  '
                                             TO QUERY

       CALL  STATIC 'exec_query_get_records' using
           BY VALUE GRAAL_ISOLATETHREAD_T
           BY CONTENT URI
           BY CONTENT USER
           BY CONTENT PWD 
           BY CONTENT QUERY
           BY REFERENCE CUS-POINTER
           returning RESULT
       END-CALL

    else
       DISPLAY 'driver_native_select_print failed'.

    SET ADDRESS OF CUS TO CUS-POINTER
    IF RESULT > 0 
       DISPLAY CUS-TITLE-DISPLAY
       DISPLAY CUS-SUB-DISPLAY
       PERFORM VARYING I FROM 1 BY 1 UNTIL I > RESULT
               MOVE CUS-ID(I) TO CUS-ID-DIS
               SET ADDRESS OF CUS-NAME-ADDR TO CUS-NAME-PTR(I)
               MOVE CUS-NAME-ADDR           TO CUS-NAME-DIS
               MOVE CUS-AGE(I)              TO CUS-AGE-DIS
               DISPLAY CUS-DISPLAY
       END-PERFORM
     END-IF.  

    CALL STATIC 'free_results' using
       BY VALUE GRAAL_ISOLATETHREAD_T 
       BY REFERENCE CUS 
       BY VALUE RESULT.   

    CALL STATIC 'graal_detach_thread' using
           BY VALUE GRAAL_ISOLATETHREAD_T 
           returning RESPONSE
    END-CALL

    IF RESPONSE NOT equal 0 then
       DISPLAY 'graal_detach_thread failed'.

    STOP RUN.
    
 MAIN-EXECQUERYGETRECORDS-EX.
    EXIT.
      
 END PROGRAM EXECQUERYGETRECORDS.
