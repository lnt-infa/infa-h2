UPDATE PC_DBRCONFIG  SET PCD_DBRCONFIGVALUE='domainName=InfaDomain;nodeName=InfaNode;ispNodeAddress=http://informatica.com:7006;repoName=MRS' WHERE PCD_DBRCONFIGKEY='logical_name';
COMMIT;