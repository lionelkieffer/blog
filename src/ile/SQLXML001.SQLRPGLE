**FREE
ctl-opt option(*nodebugio : *srcstmt)
        pgminfo(*pcml : *module)
        dftactgrp(*no) alwnull(*usrctl) datfmt(*iso);

// Set SQL behavior
exec sql set option commit = *none;

// ======================================================================================
//
//   SQLXML001 : Sample to produce XML on IFS using SQL.
//
//   Created in 2017 by Lionel KIEFFER
//
//   This is a sample code created for educational
//   purpose so no warranty is provided.
//
// ======================================================================================

// Parameters expected :
// - Company identifier.
dcl-pr SQLXML001;
   iDepartment char(3) const;
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
dcl-pi SQLXML001;
   iDepartment char(3) const;
end-pi;

// File receiving information on IFS.
dcl-s xmlFile sqltype(XML_DBCLOB_FILE);

// Sql error message.
dcl-s msgTxtSQL   char(1024);
dcl-s msgdata char(2048);
dcl-s msgKey char(4);
dcl-ds errorCode likeds(genErr_t);

xmlFile_name = 'department_' + %trim(iDepartment) + '_employees.xml';
xmlFile_nl = %len(%trim(xmlFile_name));
xmlFile_fo = SQFOVR;

// Create XML document and copy it to IFS.
exec sql
   select xmldocument(
    xmlelement(name "department", xmlattributes(deptno as "id"), xmlforest(deptname as "name", location as "location"),
    xmlelement(name "manager", xmlattributes(managers.empno as "id"), trim(managers.firstnme) || ' ' || trim(managers.lastname)),
    xmlelement(name "employees", xmlattributes(count(*) as "count"),
      xmlagg(
        xmlelement(name "employee", xmlattributes(employees.empno as "id"),
          xmlforest (trim(employees.firstnme) || ' ' || trim(employees.lastname) as "name", employees.phoneno as "phone_number",
          trim(employees.job) as "job", employees.sex as "sex", employees.birthdate as "birth_date", employees.salary as "salary")
        )
      order by employees.empno)
      )
    )
  ) into :xmlFile
from sample.employee employees join sample.department on employees.workdept = deptno
left join sample.employee managers on mgrno = managers.empno
where deptno = :iDepartment
group by deptno, deptname, location, managers.empno, managers.firstnme, managers.lastname;

exsr hdlSQLErr;

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
