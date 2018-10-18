**FREE
ctl-opt option(*nodebugio : *srcstmt)
        pgminfo(*pcml : *module)
        dftactgrp(*no) alwnull(*usrctl) datfmt(*iso);
ctl-opt bnddir ('QC2LE');

// Set SQL behavior
exec sql set option commit = *none;

// ======================================================================================
//
//   SQLXML002 : Sample to produce XML on IFS using SQL and call java tool
//               to convert it to PDF.
//
//   Created in 2018 by Lionel KIEFFER
//
//   This is a sample code created for educational
//   purpose so no warranty is provided.
//
// ======================================================================================

// Parameters expected : none.
dcl-pr SQLXML002;
end-pr;

// java method to send e-mail with attachments.
dcl-pr createPDF ind
extproc(*java : 'com.lkieffer.java4IBMI.printing.XML2PDFHelper' : 'createPDF' ) static;

  xmlPath object(*java: 'java.lang.String') const;
  xslPath object(*java: 'java.lang.String') const;
  outPath object(*java: 'java.lang.String') const;

end-pr;

// New string constructor.
dcl-pr newString object(*java: 'java.lang.String')
extproc(*java : 'java.lang.String' : *constructor );

  bytes varchar(9999) const;

end-pr;

// C API : call of putEnv() to update classpath.
dcl-pr putEnv int(10)
extproc('putenv');
  envvar pointer value options(*string);
end-pr;

// Send program messages.
dcl-pr qmhsndpm extpgm ('QMHSNDPM');
  messageId char(7) const;
  messageFile char(20) const;
  messageData char(32767) options(*varsize) const;
  messageDataLength int(10) const;
  messageType char(10) const;
  stackEntry char(10) const;
  stackCount int(10) const;
  messageKey char(4) const;
  errorCode char(32767) options(*varsize);
end-pr;

// Generic error description for IBM API's.
dcl-ds genErr_t template qualified;
  Provided int(10);
  Available int(10);
  ExceptionID char(7);
  *n char(1);
  Data char(48);
end-ds;

// -------------------------------------------------------------------------------
// Main procedure.
// ------------------------------------------------------------------------------
dcl-pi SQLXML003;
end-pi;

// File receiving information on IFS.
dcl-s xmlFile sqltype(XML_DBCLOB_FILE);

// Sql error message.
dcl-s msgTxtSQL   char(1024);
dcl-s msgdata char(2048);
dcl-s msgKey char(4);
dcl-ds errorCode likeds(genErr_t);

// Call to Java object.
dcl-s rtnCode int(10);
dcl-s xmlPath object(*java: 'java.lang.String');
dcl-s xslPath object(*java: 'java.lang.String');
dcl-s outPath object(*java: 'java.lang.String');

xmlFile_name = 'system_info.xml';
xmlFile_nl = %len(%trim(xmlFile_name));
xmlFile_fo = SQFOVR;

// Create XML document and copy it to IFS.
exec sql
WITH VERSION_INFO ( VERSION , TR_LEVEL ) AS (
   SELECT PTF_GROUP_TARGET_RELEASE, PTF_GROUP_LEVEL
   FROM QSYS2.GROUP_PTF_INFO
   WHERE PTF_GROUP_DESCRIPTION = 'TECHNOLOGY REFRESH'
     AND PTF_GROUP_STATUS = 'INSTALLED'
   ORDER BY PTF_GROUP_TARGET_RELEASE DESC FETCH FIRST 1 ROWS ONLY ),
  SYSTEM_VALUES_INFO ( INFO ) AS (
  SELECT XMLDOCUMENT(XMLELEMENT(NAME "SYSTEM_VALUES", XMLAGG(XMLELEMENT(NAME "SYSTEM_VALUE", XMLATTRIBUTES(SYSTEM_VALUE_NAME AS "NAME"), XMLFOREST(CURRENT_NUMERIC_VALUE AS "VALUE", TRIM(CURRENT_CHARACTER_VALUE) AS "VALUE")))))
  FROM QSYS2.SYSTEM_VALUE_INFO
  )
SELECT XMLDOCUMENT(XMLELEMENT(NAME "SYSTEM_INFO", XMLATTRIBUTES(HOST_NAME, VERSION_INFO.VERSION, VERSION_INFO.TR_LEVEL), XMLFOREST(MAXIMUM_JOBS_IN_SYSTEM, CURRENT_CPU_CAPACITY, SYSTEM_ASP_STORAGE, SYSTEM_ASP_USED), SYSTEM_VALUES_INFO.INFO))
  into :xmlFile
FROM QSYS2.SYSTEM_STATUS_INFO,
     VERSION_INFO,
     SYSTEM_VALUES_INFO ;

exsr hdlSQLErr;

// Set java classpath to the tool and initiate path to files to process.
rtncode = putEnv ('CLASSPATH=./libs/java4IBMI-0.0.1-SNAPSHOT.jar');
xmlPath =  newString( './resources/xml/system_info.xml' );
xslPath =  newString( './resources/xsl/system_info.xsl' );
outPath =  newString( './system_info.pdf' );

if not createPDF (xmlPath : xslPath : outPath);
  msgData = 'JAVA error during PDF creation process';

  callp qmhsndpm( 'CPF9898' : 'QCPFMSG   *LIBL'
                : msgdata : %len ( msgData )
                : '*ESCAPE': '*' : 1 : msgKey : errorCode );
endif;


*inlr = *on;
return;


// ********************************************************************
// *  Seneric SQL error handling.
// *******************************************************************
begsr hdlSQLErr;

  if sqlcode < 0;

    msgData = 'SQL error ' + %char ( sqlcode );

    // Dump error if something wrong happened and tell caller something
    // really bad occured.
    dump;

    exec sql
      get diagnostics condition 1 :msgTxtSQL = MESSAGE_TEXT;

    msgData = %trim ( msgData ) + ' -> ' + %trim ( msgTxtSQL );

    callp qmhsndpm( 'CPF9898' : 'QCPFMSG   *LIBL' :
    msgdata : %len ( msgData ) :
    '*ESCAPE': '*' : 1 : msgKey : errorCode );

  endif;
endsr;
