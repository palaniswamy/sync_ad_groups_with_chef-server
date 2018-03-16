#!/usr/bin/env python
from __future__ import print_function
import ldap

con=ldap.initialize('ldap://ldap.example.com')

user_dn = r"CN=serviceaccount,ou=users,dc=mydomain,dc=example,dc=com"
password = "<Retrieve the password securely from chef encrypted data bags>"

def get_members(cn):
  res = con.search_s(cn, ldap.SCOPE_BASE, '(objectClass=Group)')
  for result in res:
    result_dn = result[0]
    result_attrs = result[1]

    if "member" in result_attrs:
      for member in result_attrs["member"]:
        user_result = con.search_s(member, ldap.SCOPE_BASE, '(objectClass=User)')
        if user_result:
          for dn, entry in user_result:
            if "sAMAccountName" in entry:
              print(entry["sAMAccountName"][0])
            else:
              get_members(member)

if __name__ == '__main__':
  import sys
  import argparse
  argparser = argparse.ArgumentParse(prog=__file__)
  argparser.add_argument('ad_group', help='Active Directory group name')
  args = argparser.parse_args()
  try:
    con.simple_bind_s(user_dn, password)
    get_members(args.ad_group)
  except Exception, error:
    print(error)
               
