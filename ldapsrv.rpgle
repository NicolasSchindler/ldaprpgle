**FREE
Ctl-Opt NoMain;

/copy qcpysrc,LDAPSRV
/copy qcpysrc,LDAP_H

//-----------------------------------------------------------------------------
//\brief Get DN from LDAP which matches the filter
//-----------------------------------------------------------------------------
Dcl-Proc LDAPSRV_GET_DN Export;
    Dcl-Pi *N char(256);
        pConnection likeds(ConnectionDS);
        pBase char(256) value;
        pFilter char(256) value;
    End-Pi;
    Dcl-S returnDN char(256);
    Dcl-S LDAP pointer;
    Dcl-S result pointer;
    Dcl-S entry pointer;
    Dcl-S dn pointer;
    Dcl-S rc int(10);
    LDAP = ldap_init(%trim(pConnection.Host):pConnection.Port);
    rc = ldap_get_errno(LDAP);
    If rc <> LDAP_SUCCESS;
        snd-msg 'Error: ' + %str(ldap_err2string(rc):1024);
        return *BLANKS;
    EndIf;
    rc = ldap_simple_bind_s(LDAP:%trim(pConnection.User):%trim(pConnection.Password));
    If rc <> LDAP_SUCCESS;
        snd-msg 'Error: ' + %str(ldap_err2string(rc):1024);
        return *BLANKS;
    EndIf;
    If LDAP = *NULL;
        return *BLANKS;
    EndIf;
    rc = ldap_search_s(LDAP:pBase:LDAP_SCOPE_SUBTREE:pFilter:*NULL:1:result);
    If rc = LDAP_SUCCESS;
        entry = ldap_first_entry(LDAP:result);
        If entry <> *NULL;
            dn = ldap_get_dn(LDAP:entry);
            returnDN = %str(dn:256);
            ldap_memfree(dn);
        EndIf;
    EndIf;
    ldap_unbind(LDAP);
    return returnDN;
End-Proc;


//-----------------------------------------------------------------------------
//\brief Get DN with attributes from LDAP which matches the filter
//       returns a datastructure with the DN and the attributes
//-----------------------------------------------------------------------------
Dcl-Proc LDAPSRV_GET_DN_WITH_ATTRIBUTES Export;
    Dcl-Pi *N likeds(DNDS);
        pConnection likeds(ConnectionDS); 
        pBase char(256) value;
        pFilter char(256) value;
        pAttributes char(256) dim(32);
    End-Pi;
    Dcl-Ds returnDS likeds(DNDS) inz;
    Dcl-S LDAP pointer;
    Dcl-S rc int(10);
    Dcl-S x int(10) inz(1);
    Dcl-S y int(10) inz(1);
    Dcl-S z int(10) inz(1);
    Dcl-S dn pointer;
    Dcl-S result pointer;
    Dcl-S entry pointer;
    Dcl-S berptr pointer;
    Dcl-S attribute pointer;
    Dcl-S values pointer;
    Dcl-S valuesArray pointer based(values) dim(256);
    Dcl-S strPtr pointer;
    Dcl-S AttributeChar char(256);
    Dcl-S attrArray pointer dim(32);

    For-each AttributeChar in pAttributes;
        If AttributeChar <> *BLANK;
            strPtr = %alloc(%len(AttributeChar));
            %str(strPtr:%len(%trim(AttributeChar)) + 1) = AttributeChar;
            attrArray(y) = strPtr;
        Else;
            attrArray(y) = *NULL;
        EndIf;
        y += 1;
    EndFor;
    LDAP = ldap_init(%trim(pConnection.Host):pConnection.Port);
    rc = ldap_get_errno(LDAP);
    If rc <> LDAP_SUCCESS;
        snd-msg 'Error: ' + %str(ldap_err2string(rc):1024);
        return returnDS;
    EndIf;
    rc = ldap_simple_bind_s(LDAP:%trim(pConnection.User):%trim(pConnection.Password));
    If rc <> LDAP_SUCCESS;
        snd-msg 'Error: ' + %str(ldap_err2string(rc):1024);
        return returnDS;
    EndIf;

    rc = ldap_search_s(LDAP:pBase:LDAP_SCOPE_SUBTREE:pFilter:%addr(attrArray):0:result);
    If rc = LDAP_SUCCESS;
        entry = ldap_first_entry(LDAP:result);
        If entry <> *NULL;
            dn = ldap_get_dn(LDAP:entry);
            returnDS.Name = %str(dn:256);
            attribute = ldap_first_attribute(LDAP:entry:berptr);
            z = 1;
            Dow attribute <> *NULL and z <= 32;
                returnDS.Attributes(z).Attribute = %str(attribute:256);
                values = ldap_get_values(LDAP:entry:attribute);
                If values <> *NULL;
                    x = 1;
                    Dow x <= 256 and valuesArray(x) <> *NULL;
                        returnDS.Attributes(z).Values(x) = %str(valuesArray(x):256);
                        x += 1;
                    EndDo;
                EndIf;
                ldap_value_free(values);
                attribute = ldap_next_attribute(LDAP:entry:berptr);
                z += 1;
            EndDo;
            ldap_memfree(dn);
        EndIf;
    EndIf;

    ldap_unbind(LDAP);
    return returnDS;
End-Proc;

//-----------------------------------------------------------------------------
//\brief Checks whether the LDAP DN has an attribute with a specific value
//-----------------------------------------------------------------------------
Dcl-Proc LDAPSRV_HAS_DN_ATTRIBUTE_WITH_VALUE Export;
    Dcl-Pi *N ind;
        pConnection likeds(ConnectionDS);
        pDN char(256) value;
        pAttributes char(256) value;
        pValue char(256) value;
    End-Pi;
    Dcl-S rc int(10);
    Dcl-S LDAP pointer;
    LDAP = ldap_init(%trim(pConnection.Host):pConnection.Port);
    rc = ldap_get_errno(LDAP);
    If rc <> LDAP_SUCCESS;
        snd-msg 'Error: ' + %str(ldap_err2string(rc):1024);
        return *Off;
    EndIf;
    rc = ldap_simple_bind_s(LDAP:%trim(pConnection.User):%trim(pConnection.Password));
    If rc <> LDAP_SUCCESS;
        snd-msg 'Error: ' + %str(ldap_err2string(rc):1024);
        return *Off;
    EndIf;
    rc = ldap_compare_s(LDAP:pDN:pAttributes:pValue);

    ldap_unbind(LDAP);
    If rc = LDAP_COMPARE_TRUE;
        return *On;
    ElseIf rc = LDAP_COMPARE_FALSE;
        return *Off;
    EndIf;
    snd-msg 'Error: ' + %str(ldap_err2string(rc):1024);
    return *Off;
End-Proc;
