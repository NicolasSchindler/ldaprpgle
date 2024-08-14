# How to connect a LDAP Server to IBM i

In this Project i provide a simple example how to connect to a LDAP Server from IBM i. 
I added some Constants and Functions from the LDAP Headerfile provided by IBM, not all Functions are implemented in this example. 
The Serviceprogramm is written in Free Format RPGLE and uses the provided LDAP API written in C, which is included in the OS.
The Documentation of the LDAP API can be found [here](https://www.ibm.com/docs/api/v1/content/ssw_ibm_i_75/apis/dirserv2.htm)

Thanks to @ScottKlement, who has published an example of a copybook on his site, which I have used as a guide. You can find his example [here](https://www.scottklement.com/rpg/copybooks/ldap_h.rpgle.txt).
Also thanks to @m1h43l for helping me with handling the null-terminated strings in the RPG Code.

## How to use this example

You can install the Serviceprogramm, by copying the sources provided in the Files below to your IBM i and compile it. 

## Examples

1. Getting DN for Entry where Attribute fullname "Nicolas Schindler"
```rpgle
Dcl-S filter char(256);
Dcl-S base char(256);
Dcl-Ds Connection likeds(ConnectionDS);

base = 'OU=ACME,DC=internal';
filter = '(&(objectclass=person)(fullname=Nicolas Schindler))';
Connection.Host = '<YOUR-LDAP-SERVER>';
Connection.Port = LDAP_PORT; // or LDAPS_PORT for SSL
Connection.User = '<YOUR-LDAP_USER>';
Connection.Password = 'SUPER_SECRET_PASSWORD';

DN = LDAPSRV_GET_DN(Connection:base:filter);

snd-msg 'DN for Nicolas Schindler is: ' + DN;
```

2. Getting Entry with Attribute memberOf for DN "CN=Nicolas Schindler,OU=ACME,DC=internal"
```rpgle
Dcl-S filter char(256);
Dcl-S base char(256);
Dcl-S attributes char(256) dim(32) inz;
Dcl-S value char(256);                     
Dcl-Ds Attr likeds(AttributeDS);
Dcl-Ds Connection likeds(ConnectionDS);
Dcl-Ds Entry likeds(DNDS) inz;

attributes(1) = 'memberOf';
base = 'OU=ACME,DC=internal';
filter = '(&(objectclass=person)(distinguishedName=CN=Nicolas Schindler,OU=ACME,DC=internal))';
Connection.Host = '<YOUR-LDAP-SERVER>';
Connection.Port = LDAP_PORT; // or LDAPS_PORT for SSL
Connection.User = '<YOUR-LDAP_USER>';
Connection.Password = 'SUPER_SECRET_PASSWORD';

Entry = LDAPSRV_GET_DN_WITH_ATTRIBUTES(Connection:base:filter:attributes);

For-Each Attr in Entry.Attributes;
    If Attr.Attribute <> *blank;
        snd-msg 'Attribute: ' + Attr.Attribute;
        For-Each value in Attr.Values;
            If value <> *blank;
                snd-msg 'Value: ' + value;
            EndIf;
        EndFor;
    EndIf;
EndFor;  
```

3. Check if DN Entry have the Attribute memberOf with Value "CN=Admins,OU=ACME,DC=internal"
```rpgle
Dcl-S DN char(256);
Dcl-S attribute char(256);
Dcl-S value char(256);              
Dcl-Ds Connection likeds(ConnectionDS);

attribute = 'memberOf';
value = 'CN=Admins,OU=ACME,DC=internal';
DN = 'distinguishedName=CN=Nicolas Schindler,OU=ACME,DC=internal';
Connection.Host = '<YOUR-LDAP-SERVER>';
Connection.Port = LDAP_PORT; // or LDAPS_PORT for SSL
Connection.User = '<YOUR-LDAP_USER>';
Connection.Password = 'SUPER_SECRET_PASSWORD';

If LDAPSRV_HAS_DN_ATTRIBUTE_WITH_VALUE(Connection:DN:attribute:value);
    snd-msg 'DN has Attribute memberOf with Value CN=Admins,OU=ACME,DC=internal';
Else;
    snd-msg 'DN has not Attribute memberOf with Value CN=Admins,OU=ACME,DC=internal';
EndIf;
```
